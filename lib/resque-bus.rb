require 'redis/namespace'
require 'resque'

require "resque_bus/version"
require 'resque_bus/application'
require 'resque_bus/driver'
require 'resque_bus/rider'
require 'resque_bus/dispatch'

module ResqueBus
  extend self

  def app_key=key
    @application = Application.new(key)
  end
  def application
    @application ||= Application.new("unknown")
  end
  
  def dispatch(&block)
    @dispatcher = Dispatch.new
    @dispatcher.instance_eval(&block)
    @dispatcher
  end
  
  def dispatcher
    @dispatcher
  end

  # Accepts:
  #   1. A 'hostname:port' String
  #   2. A 'hostname:port:db' String (to select the Redis db)
  #   3. A 'hostname:port/namespace' String (to set the Redis namespace)
  #   4. A Redis URL String 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
  #      or `Redis::Namespace`.
  def redis=(server)
    case server
    when String
      if server =~ /redis\:\/\//
        redis = Redis.connect(:url => server, :thread_safe => true)
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(:host => host, :port => port,
          :thread_safe => true, :db => db)
      end
      namespace ||= default_namespace

      @redis = Redis::Namespace.new(namespace, :redis => redis)
    when Redis::Namespace
      @redis = server
    else
      @redis = Redis::Namespace.new(default_namespace, :redis => server)
    end
  end

  # Returns the current Redis connection. If none has been created, will
  # create a new one from the Reqsue one (with a different namespace)
  def redis
    return @redis if @redis
    copy = Resque.redis.clone
    copy.namespace = default_namespace
    self.redis = copy
    self.redis
  end
  
  def publish_metadata(event_type, attributes={})
    bus_attr = {"bus_published_at" => Time.now.to_i, "bus_app_key" => application.app_key, "created_at" => Time.now.to_i}
    an_id = attributes["id"] || "#{Time.now.to_i}_#{rand(999999999)}"
    bus_attr["bus_id"] = "#{application.app_key}::#{an_id}"
    bus_attr.merge(attributes || {})
  end
  
  def publish(event_type, attributes = {})
    # TDOO: add logging. It will be important to be able to follow these through, say in splunk.
    to_publish = publish_metadata(event_type, attributes)
    ResqueBus.log_application("Event published: #{event_type} #{to_publish.inspect}")
    enqueue_to(incoming_queue, Driver, event_type, to_publish)
  end
  
  def subscribe(app_name, event_types)
    Application.new(app_name).subscribe(event_types)
  end
  
  def unsubscribe(app_name)
    Application.new(app_name).unsubscribe
  end
  
  def enqueue_to(queue, klass, event_type_or_match, attributes)
    push(queue, :class => klass.to_s, :args => [event_type_or_match, attributes])
  end
  
  def logger
    @logger
  end
  
  def logger=val
    @logger = val
  end
  
  def log_application(message)
    if logger
      time = Time.now.strftime('%H:%M:%S %Y-%m-%d')
      logger.info("** [#{time}] #$$: ResqueBus #{message}")
    end
  end
  
  def log_worker(message)
    if ENV['LOGGING'] || ENV['VERBOSE'] || ENV['VVERBOSE']
      time = Time.now.strftime('%H:%M:%S %Y-%m-%d')
      puts "** [#{time}] #$$: #{message}"
    end
  end
  
  protected
  
  def reset
    # used by tests
    @redis = nil # clear instance of redis
    @application = nil
    @dispatcher = nil
  end
  
  def incoming_queue
    "resquebus_incoming"
  end

  def default_namespace
    # TODO: should we do a different one?
    # It might play better on the same server, but overall life is more complicated
    :resque
  end
  
  ## From Resque, but using a (possibly) different instance of Redis
  
  # Pushes a job onto a queue. Queue name should be a string and the
  # item should be any JSON-able Ruby object.
  #
  # Resque works generally expect the `item` to be a hash with the following
  # keys:
  #
  #   class - The String name of the job to run.
  #    args - An Array of arguments to pass the job. Usually passed
  #           via `class.to_class.perform(*args)`.
  #
  # Example
  #
  #   Resque.push('archive', :class => 'Archive', :args => [ 35, 'tar' ])
  #
  # Returns nothing
  def push(queue, item)
    watch_queue(queue)
    redis.rpush "queue:#{queue}", Resque.encode(item)
  end
  
  # Used internally to keep track of which queues we've created.
  # Don't call this directly.
  def watch_queue(queue)
    redis.sadd(:queues, queue.to_s)
  end
  
end
