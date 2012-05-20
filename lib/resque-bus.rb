require 'redis/namespace'
require 'resque'

require "resque_bus/version"
require 'resque_bus/application'
require 'resque_bus/driver'
require 'resque_bus/rider'
require 'resque_bus/routes'

module ResqueBus
  extend self

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
  
  def publish(event_type, attributes = {})
    enqueue_to(incoming_queue, Driver, event_type, attributes)
  end
  
  def subscribe(app_name, event_types)
    Application.new(app_name).subscribe(event_types)
  end
  
  def unsubscribe(app_name)
    Application.new(app_name).unsubscribe
  end
  
  def enqueue_to(queue, klass, event_type_or_match, attributes={})
    push(queue, :class => klass.to_s, :args => [event_type_or_match, attributes || {}])
  end
  
  protected
  
  def reset
    # used by tests
    @redis = nil # clear instance of redis
  end
  
  def incoming_queue
    "incoming"
  end

  def default_namespace
    :resquebus
  end
  
  ## From Resque, but using our instance of Redis
  
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
