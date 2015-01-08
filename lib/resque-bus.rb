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
    
    def redis
      Resque.redis
    end
    
    protected
    
    def reset
      # used by tests
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