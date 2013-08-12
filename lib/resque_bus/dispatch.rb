# Creates a DSL for apps to define their blocks to run for event_types

module ResqueBus
  class Dispatch
    attr_reader :app_key, :subscriptions
    def initialize(app_key)
      @app_key = Application.normalize(app_key)
      @subscriptions = SubscriptionList.new
    end
    
    def size
      @subscriptions.size
    end
    
    def subscribe(key, matcher_hash = nil, &block)
      dispatch_event("default", key, matcher_hash, block)
    end
    
    # allows definitions of other queues
    def method_missing(method_name, *args, &block)
      if args.size == 1 and block
        dispatch_event(method_name, args[0], nil, block)
      elsif args.size == 2 and block
        dispatch_event(method_name, args[0], args[1], block)
      else
        super
      end
    end
    
    def execute(key, attributes)
      sub = subscriptions.key(key)
      if sub
        sub.execute!(attributes)
      else
        # TODO: log that it's not there
      end
    end

    def subscription_matches(attributes)
      out = subscriptions.matches(attributes)
      out.each do |sub|
        sub.app_key = self.app_key
      end
      out
    end
    
    def dispatch_event(queue, key, matcher_hash, block)
      # if not matcher_hash, assume key is a event_type regex
      matcher_hash ||= { "bus_event_type" => key }
      add_subscription("#{app_key}_#{queue}", key, "::ResqueBus::Rider", matcher_hash, block)
    end
    
    def add_subscription(queue_name, key, class_name, matcher_hash = nil, block)
      sub = Subscription.register(queue_name, key, class_name, matcher_hash, block)
      subscriptions.add(sub)
      sub
    end
  end
end
