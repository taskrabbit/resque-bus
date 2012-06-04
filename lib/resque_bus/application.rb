module ResqueBus
  class Application
    attr_reader :app_key, :redis_key
    
    def self.all
      # note the names arent the same as we started with
      ResqueBus.redis.smembers(app_list_key).collect{ |val| new(val) }
    end
    
    def initialize(app_key)
      @app_key = self.class.normalize(app_key)
      @redis_key = "#{self.class.app_single_key}:#{@app_key}"
      # raise error if only other chars
      raise "Invalid application name" if @app_key.gsub("_", "").size == 0
    end
    
    def subscribe(event_types)
      if event_types == nil || event_types.to_s == "" || event_types == [] || event_types == {}
        unsubscribe
        return true
      end
      
      temp_key = "temp_#{redis_key}:#{rand(999999999)}"
      
      queues = []
      # if event_types is an array, make a hash wih the default queue #{app_name}_#{default_queue}
      if event_types.is_a? Hash
        event_types.each do |event, queue|
          queue = self.class.normalize(queue)
          queue = "default" if queue.size == 0
          queue = "#{app_key}_#{queue}"
          ResqueBus.redis.hset(temp_key, event.to_s, queue)
          queues << queue
        end
      else
        event_types = [event_types] unless event_types.is_a? Array
        event_types.each do |type|
          queue = "#{app_key}_default"
          ResqueBus.redis.hset(temp_key, type.to_s, queue)
          queues << queue
        end
      end

      
      # make it the real one
      ResqueBus.redis.rename(temp_key, redis_key)
      ResqueBus.redis.sadd(self.class.app_list_key, app_key)
      true
    end
    
    def unsubscribe
      # TODO: clean up known queues
      ResqueBus.redis.srem(self.class.app_list_key, app_key)
      ResqueBus.redis.del(redis_key)
    end
    
    def queues
      out = ResqueBus.redis.hvals(redis_key)
      out ||= []
      out << "#{app_key}_default"
      out.uniq
    end
    
    def event_queues
      ResqueBus.redis.hgetall(redis_key)
    end
    
    def events
      ResqueBus.redis.hkeys(redis_key).uniq
    end
    
    def event_matches(event)
      event_queues.reject{ |k,_| !event_matches?(k, event) }
    end
    
    def event_display
      out = []
      event_queues.each do |mine, queue|
        if mine[0..6] == "(?-mix:"
          # TODO: figure out reverse label
          val = mine
        else
          val = mine
        end
        out << [val, queue.to_s]
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
    
    def event_matches?(mine, given)
      mine = mine.to_s
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
    
  end
end