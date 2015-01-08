module ResqueBus
  class Subscription

    class << self
      def register(queue, key, class_name, matcher, block)
        Subscription.new(queue, key, class_name, matcher, block)
      end
      
      def from_redis(hash)
        queue_name = hash["queue_name"].to_s
        key        = hash["key"].to_s
        class_name = hash["class"].to_s
        matcher    = hash["matcher"]
        return nil if key.length == 0 || queue_name.length == 0
        Subscription.new(queue_name, key, class_name, matcher, nil)
      end

      def normalize(val)
        val.to_s.gsub(/\W/, "_").downcase
      end
    end

    attr_reader :matcher, :executor, :queue_name, :key, :class_name
    attr_accessor :app_key  # dyanmically set on return from subscription_matches
    
    def initialize(queue_name, key, class_name, filters, executor=nil)
      @queue_name = self.class.normalize(queue_name)
      @key        = key.to_s
      @class_name = class_name.to_s
      @matcher    = Matcher.new(filters)
      @executor   = executor
    end
    
    def execute!(attributes)
      attributes = attributes.with_indifferent_access if attributes.respond_to?(:with_indifferent_access)
      ::ResqueBus.with_global_attributes(attributes) do
        executor.call(attributes)
      end
    end
    
    def matches?(attributes)
      @matcher.matches?(attributes)
    end

    def to_redis
      out = {}
      out["queue_name"] = queue_name
      out["key"]        = key
      out["class"]      = class_name
      out["matcher"]    = matcher.to_redis
      out
    end

  end
end