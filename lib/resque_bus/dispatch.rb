# Creates a DSL for apps to define their blocks to run for event_types

module ResqueBus
  class Dispatch    
    def initialize
      @subscriptions = SubscriptionList.new
    end
    
    def size
      @subscriptions.size
    end
    
    def subscribe(key, matcher_hash = nil, &block)
      register_event("default", key, matcher_hash, block)
    end
    
    # allows definitions of other queues
    def method_missing(method_name, *args, &block)
      if args.size == 1 and block
        register_event(method_name, args[0], nil, block)
      elsif args.size == 2 and block
        register_event(method_name, args[0], args[1], block)
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

    def subscriptions
      @subscriptions
    end

    def subscription_matches(attributes)
      subscriptions.matches(attributes)
    end
    
    protected
    
    
    def register_event(queue, key, matcher_hash, block)
      # if not matcher_hash, assume key is a event_type regex
      matcher_hash ||= { "event_type" => key }
      sub = Subscription.register(queue, key, matcher_hash, block)
      subscriptions.add(sub)
    end
  end
end
