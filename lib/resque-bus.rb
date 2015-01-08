require "resque_bus/version"

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
  autoload :Worker,           'resque_bus/worker'

  module Adapters
    autoload :Base,           'resque_bus/adapters/base'
    autoload :Resque,         'resque_bus/adapters/resque'
  end

  class << self

    include Publishing
    include Heartbeating
    extend Forwardable

    def_delegators :config, :default_app_key=, :default_app_key,
                            :default_queue=, :default_queue,
                            :local_mode=, :local_mode,
                            :before_publish=, :before_publish_callback,
                            :logger=, :logger, :log_application, :log_worker,
                            :hostname=, :hostname,
                            :adapter=, :adapter,
                            :redis

    def_delegators :_dispatchers, :dispatch, :dispatchers, :dispatcher_by_key, :dispatcher_execute
    
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
  end
  
end