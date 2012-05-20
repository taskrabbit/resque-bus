module ResqueBus
  class Application
    attr_reader :name, :key
    def initialize(name)
      @name = name
      @key = self.class.normalize_key(name)
      # raise error if only other chars
      raise "Invalid application name" if @key.gsub("_", "").size == 0
    end
    
    def subscribe(event_types)
      if event_types == nil || event_types == "" || event_types == [] || event_types == {}
        unsubscribe
        return true
      end
      
      temp_key = "temp_#{app_key}:#{rand(999999999)}"
      
      queues = []
      # if event_types is an array, make a hash wih the default queue #{app_name}_#{default_queue}
      if event_types.is_a? Hash
        event_types.each do |event, queue|
          queue = self.class.normalize_key(queue)
          queue = "default" if queue.size == 0
          queue = "#{key}_#{queue}"
          ResqueBus.redis.hset(temp_key, event, queue)
          queues << queue
        end
      else
        event_types = [event_types] unless event_types.is_a? Array
        event_types.each do |type|
          queue = "#{key}_default"
          ResqueBus.redis.hset(temp_key, type.to_s, queue)
          queues << queue
        end
      end

      
      # make it the real one
      ResqueBus.redis.rename(temp_key, app_key)
      ResqueBus.redis.sadd(:apps, key)
      true
    end
    
    def unsubscribe
      ResqueBus.redis.srem(:apps, key)
      ResqueBus.redis.del(app_key)
    end
    
    def queues
      out = ResqueBus.redis.hvals(app_key)
      out ||= []
      out << "#{key}_default"
      out.uniq
    end
    
    def events
      ResqueBus.redis.hgetall(app_key) || {}
    end
    
    protected
    
    def app_key
      "app:#{key}"
    end
    
    def self.normalize_key(key)
      key.to_s.gsub(/\W/, "_").downcase
    end
    
  end
end