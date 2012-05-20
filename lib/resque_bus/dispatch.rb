# Creates a DSL for apps to define their blocks to run for event_types

module ResqueBus
  class Dispatch
    attr_reader :subscriptions
    
    def initialize
      @subscriptions = {}
    end
    
    def subscribe(event_type, &block)
      subscriptions[event_type.to_s] = block
    end
    
    def execute(event_type, attributes)
      proc = subscriptions[event_type.to_s]
      if proc
        proc.call(attributes)
      else
        # TODO: log that it's not there
      end
    end
  end
end