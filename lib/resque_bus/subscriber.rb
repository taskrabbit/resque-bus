module ResqueBus
  module Subscriber
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def application(app_key)
        @app_key = ::ResqueBus::Application.normalize(app_key)
      end
      
      def app_key
        return @app_key if @app_key
        @app_key = ::ResqueBus.default_app_key
        return @app_key if @app_key
        # module or class_name
        val = self.name.to_s.split("::").first
        @app_key = ::ResqueBus::Util.underscore(val)
      end
      
      def subscribe(method_name, matcher_hash = nil)
        queue_name   = ::Resque.queue_from_class(self)
        queue_name ||= ::ResqueBus.default_queue
        subscribe_queue(queue_name, method_name, matcher_hash)
      end
      
      def subscribe_queue(queue_name, method_name, matcher_hash = nil)
        klass = self
        matcher_hash ||= {"bus_event_type" => method_name}
        sub_key = "#{self.name}.#{method_name}"
        dispatcher = ::ResqueBus.dispatcher_by_key(app_key)
        dispatcher.add_subscription(queue_name, sub_key, klass.name.to_s, matcher_hash, lambda{ |att| klass.perform(att) })
      end
      
      def transform(method_name)
        @transform = method_name
      end
      def perform(attributes)
        sub_key = attributes["bus_rider_sub_key"]
        meth_key = sub_key.split(".").last
        resque_bus_execute(meth_key, attributes)
      end
      
      def resque_bus_execute(key, attributes)
        args = attributes
        args = send(@transform, attributes) if @transform
        args = [args] unless args.is_a?(Array)
        if self.respond_to?(:subscriber_with_attributes)
          me = self.subscriber_with_attributes(attributes)
        else
          me = self.new
        end
        me.send(key, *args)
      end
    end
  end
end