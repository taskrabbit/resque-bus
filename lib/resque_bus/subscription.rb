module ResqueBus
  class Subscription
    def self.register(queue, key, matcher, block)
      Subscription.new(queue, key, matcher, block)
    end
    
    def self.from_redis(hash)
      queue_name = hash["queue_name"].to_s
      key        = hash["key"].to_s
      matcher    = hash["matcher"]
      return nil if key.length == 0 || queue_name.length == 0
      Subscription.new(queue_name, key, matcher, nil)
    end
    
    def to_redis
      out = {}
      out["queue_name"] = queue_name
      out["key"]        = key
      out["matcher"]    = matcher.to_redis
      out
    end

    attr_reader :matcher, :executor, :queue_name, :key
    def initialize(queue_name, key, filters, executor=nil)
      @queue_name = self.class.normalize(queue_name)
      @key        = key.to_s
      @matcher    = Matcher.new(filters)
      @executor   = executor
    end
    
    def execute!(attributes)
      attributes = attributes.with_indifferent_access if attributes.respond_to?(:with_indifferent_access)
      executor.call(attributes)
    end
    
    def matches?(attributes)
      @matcher.matches?(attributes)
    end
    
    protected
    
    def self.normalize(val)
      val.to_s.gsub(/\W/, "_").downcase
    end
  end
end