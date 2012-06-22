# Creates a DSL for apps to define their blocks to run for event_types

module ResqueBus
  class Dispatch
    attr_reader :subscriptions
    
    def initialize
      @subscriptions = {}
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
      queue, proc = subscriptions[event_type.to_s]
      if proc
        proc.call(attributes)
      else
        # TODO: log that it's not there
      end
    end
    
    def event_queues
      out = {}
      subscriptions.each do |event_type, tuple|
        queue, proc = tuple
        out[event_type] = queue
      end
      out
    end
    
    protected
    
    def register_event(queue, event_type, block)
      subscriptions[event_type.to_s] = [queue.to_s, block]
    end
  end
end