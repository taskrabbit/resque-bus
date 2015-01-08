require "resque_bus/version"

require 'redis/namespace'
require 'resque'

module ResqueBus
  
  autoload :Application,      'resque_bus/application'
  autoload :Config,           'resque_bus/config'
  autoload :Dispatch,         'resque_bus/dispatch'
  autoload :Dispatchers,      'resque_bus/dispatchers'
  autoload :Driver,           'resque_bus/driver'
  autoload :Heartbeat,        'resque_bus/heartbeat'
  autoload :Heartbeating,     'resque_bus/heartbeating'
  autoload :Local,            'resque_bus/local'
  autoload :Matcher,          'resque_bus/matcher'
  autoload :Publishing,       'resque_bus/publishing'
  autoload :Publisher,        'resque_bus/publisher'
  autoload :Rider,            'resque_bus/rider'
  autoload :Subscriber,       'resque_bus/subscriber'
  autoload :Subscription,     'resque_bus/subscription'
  autoload :SubscriptionList, 'resque_bus/subscription_list'
  autoload :TaskManager,      'resque_bus/task_manager'
  autoload :Util,             'resque_bus/util'

  class << self

    include Publishing
    include Heartbeating
    extend Forwardable

    def_delegators :config, :default_app_key=, :default_app_key,
                            :default_queue=, :default_queue,
                            :local_mode=, :local_mode,
                            :before_publish=, :before_publish_callback,
                            :logger=, :logger, :log_application, :log_worker,
                            :hostname=, :hostname

    def_delegators :_dispatchers, :dispatch, :dispatchers, :dispatcher_by_key, :dispatcher_execute
    

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
    
    def original_redis=(server)
      @original_redis = server
    end
    def original_redis
      @original_redis
    end
    
    protected
    
    def reset
      # used by tests
      @redis = nil
      @original_redis = nil
      @config = nil
      @_dispatchers = nil
    end

    def config
      @config ||= ::ResqueBus::Config.new
    end

    def _dispatchers
      @_dispatchers ||= ::ResqueBus::Dispatchers.new
    end

    
    def incoming_queue
      "resquebus_incoming"
    end

    def default_namespace
      # It might play better on the same server, but overall life is more complicated
      :resque
    end
  end
  
end