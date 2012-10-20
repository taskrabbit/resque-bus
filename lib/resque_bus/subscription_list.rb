module ResqueBus
  class SubscriptionList
    def self.from_redis(redis_hash)
      out = SubscriptionList.new
      
      redis_hash.each do |key, value|
        if value.is_a? String
          # old style - just a queue_name
          pieces = value.split("_")
          pieces.shift if pieces.size > 1
          queue = pieces.join("_")
          event_type = key
          properties = {}
          sub = Subscription.new(queue, event_type, properties)
        else
          # hash
          sub = Subscription.from_redis(value)
        end
        out.add(sub)
      end
      out
    end
    
    def to_redis
      out = {}
      @subscriptions.each do |key, sub|
        out[key] = sub.to_redis
      end
      out
    end
    
    def initialize
      @subscriptions = {}
    end
    
    def add(sub)
      @subscriptions[sub.key] = sub
    end
    
    def size
      @subscriptions.size
    end
    
    def key(key)
      @subscriptions[key.to_s]
    end
    
    def all
      @subscriptions.values
    end
    
    def matches(event_type)
      out = []
      all.each do |sub|
        out << sub if sub.matches?(event_type)
      end
      out
    end
  end
end