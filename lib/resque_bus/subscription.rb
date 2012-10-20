module ResqueBus
  class Subscription
    def self.register(queue, event_type, filters, block)
      Subscription.new(queue, event_type, filters, block)
    end
    
    def self.from_redis(hash)
      queue_name = hash["queue_name"]
      event_type = hash["event_type"]
      Subscription.new(queue_name, event_type, {}, nil)
    end
    
    def to_redis
      out = {}
      out["queue_name"] = queue_name
      out["event_type"] = event_type
      out
    end

    def initialize(queue_name, event_type, properties, executor=nil)
      @queue_name = self.class.normalize(queue_name)
      @event_type = event_type.to_s
      @properties = properties
      @executor = executor
    end
    
    def queue_name
      @queue_name
    end
    
    def event_name
      event_type
    end
    
    def key
      event_type
    end
    
    def execute!(attributes)
      attributes = attributes.with_indifferent_access if attributes.respond_to?(:with_indifferent_access)
      executor.call(attributes)
    end
    
    def matches?(given)
      mine = event_type.to_s
      given = given.to_s
      return true if mine == given
      begin
        # if it's already a regex, don't mess with it
        # otherwise, it should ahve start and end line situation
        if mine[0..6] == "(?-mix:"
          regex = Regexp.new(mine)
        else
          regex = Regexp.new("^#{mine}$")
        end
        return !!regex.match(given)
      rescue
        return false
      end
    end
    
    protected
    
    def self.normalize(val)
      val.to_s.gsub(/\W/, "_").downcase
    end
    
    def event_type
      @event_type
    end

    def properties
      @properties
    end
    
    def executor
      @executor
    end    
  end
end