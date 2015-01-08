module ResqueBus
  class Application

    class << self
    
      def all
        # note the names arent the same as we started with
        ::ResqueBus.redis.smembers(app_list_key).collect{ |val| new(val) }
      end
    end

    attr_reader :app_key, :redis_key

    
    def initialize(app_key)
      @app_key = self.class.normalize(app_key)
      @redis_key = "#{self.class.app_single_key}:#{@app_key}"
      # raise error if only other chars
      raise "Invalid application name" if @app_key.gsub("_", "").size == 0
    end
    
    def subscribe(subscription_list, log = false)
      @subscriptions = nil
      
      if subscription_list == nil || subscription_list.size == 0
        unsubscribe
        return true
      end
      
      temp_key = "temp_#{redis_key}:#{rand(999999999)}"
      
      redis_hash = subscription_list.to_redis
      redis_hash.each do |key, hash|
        ::ResqueBus.redis.hset(temp_key, key, ResqueBus::Util.encode(hash))
      end
      
      # make it the real one
      ::ResqueBus.redis.rename(temp_key, redis_key)
      ::ResqueBus.redis.sadd(self.class.app_list_key, app_key)
      
      if log
        puts ::ResqueBus.redis.hgetall(redis_key).inspect
      end
      
      true
    end
        
    def unsubscribe
      # TODO: clean up known queues?
      ::ResqueBus.redis.srem(self.class.app_list_key, app_key)
      ::ResqueBus.redis.del(redis_key)
    end
    
    def no_connect_queue_names_for(subscriptions)
      out = []
      subscriptions.all.each do |sub|
        queue = "#{app_key}_#{sub.queue_name}"
        out << queue
      end
      out << "#{app_key}_default"
      out.uniq
    end
    
    def subscription_matches(attributes)
      out = subscriptions.matches(attributes)
      out.each do |sub|
        sub.app_key = self.app_key
      end
      out
    end
    
    def event_display_tuples
      out = []
      subscriptions.all.each do |sub|
        out << [sub.class_name, sub.queue_name, sub.matcher.filters]
      end
      out
    end
    
    protected

    def self.normalize(val)
      val.to_s.gsub(/\W/, "_").downcase
    end
    
    def self.app_list_key
      "resquebus_apps"
    end
    
    def self.app_single_key
      "resquebus_app"
    end
    
    def event_queues
      ::ResqueBus.redis.hgetall(redis_key)
    end
    
    def subscriptions
      @subscriptions ||= SubscriptionList.from_redis(read_redis_hash)
    end
    
    def read_redis_hash
      out = {}
      ::ResqueBus.redis.hgetall(redis_key).each do |key, val|
        begin
          out[key] = ::ResqueBus::Util.decode(val)
        rescue ::ResqueBus::Util::DecodeException
          out[key] = val
        end
      end
      out
    end
   
  end
end
