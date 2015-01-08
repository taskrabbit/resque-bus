module ResqueBus
  class Dispatchers
    def dispatch(app_key=nil, &block)
      dispatcher = dispatcher_by_key(app_key)
      dispatcher.instance_eval(&block)
      dispatcher
    end
    
    def dispatchers
      @dispatchers ||= {}
      @dispatchers.values
    end
    
    def dispatcher_by_key(app_key)
      app_key = Application.normalize(app_key || ::ResqueBus.default_app_key)
      @dispatchers ||= {}
      @dispatchers[app_key] ||= Dispatch.new(app_key)
    end
    
    def dispatcher_execute(app_key, key, attributes)
      @dispatchers ||= {}
      dispatcher = @dispatchers[app_key]
      dispatcher.execute(key, attributes) if dispatcher
    end
  end
end
