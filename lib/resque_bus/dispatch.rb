# Creates a DSL for apps to define their blocks to run for event_types

module ResqueBus
  class Dispatch    
    def initialize
      @subscriptions = SubscriptionList.new
    end
    
    def size
      @subscriptions.size
    end
    
    def subscribe(event_type, &block)
      register_event("default", event_type, block)
    end
    
    # allows definitions of other queues
    def method_missing(method_name, *args, &block)
      if args.size == 1 and block
        register_event(method_name, args.first, block)
      else
        super
      end
    end
    
    def execute(event_type, attributes)
      sub = subscriptions.key(event_type)
      if sub
        sub.execute!(attributes)
      else
        # TODO: log that it's not there
      end
    end

    def subscriptions
      @subscriptions
    end

    def subscription_matches(event_type)
      subscriptions.matches(event_type)
    end
    
    protected
    
    
    def register_event(queue, event_type, block)
      sub = Subscription.register(queue, event_type, {}, block)
      subscriptions.add(sub)
    end
  end
end
