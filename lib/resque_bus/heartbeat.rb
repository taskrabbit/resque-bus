module ResqueBus
  # publishes event about the current time
  class Heartbeat

    class << self
      
      def lock_key
        "resquebus:heartbeat:lock"
      end
      
      def lock_seconds
        60
      end
      
      def lock!
        now = Time.now.to_i
        timeout = now + lock_seconds + 2

        # return true if we successfully acquired the lock
        return timeout if Resque.redis.setnx(lock_key, timeout)

        # see if the existing timeout is still valid and return false if it is
        # (we cannot acquire the lock during the timeout period)
        return 0 if now <= Resque.redis.get(lock_key).to_i

        # otherwise set the timeout and ensure that no other worker has
        # acquired the lock
        if now > Resque.redis.getset(lock_key, timeout).to_i
          return timeout
        else
          return 0
        end
      end
      
      def unlock!
        Resque.redis.del(lock_key)
      end
      
      
      def redis_key
        "resquebus:heartbeat:timestamp"
      end

      def get_saved_minute!
        key = ResqueBus.redis.get(redis_key)
        return nil if key.nil?
        return key.to_i
      end

      def set_saved_minute!(epoch_minute)
        ResqueBus.redis.set(redis_key, epoch_minute)
      end
      
      def perform
        real_now = Time.now.to_i
        run_until = lock! - 2
        return if run_until < real_now
        
        while((real_now = Time.now.to_i) < run_until)
          minutes = real_now.to_i / 60
          last = get_saved_minute!
          if last
            break if minutes <= last
            minutes = last + 1
          end

          seconds = minutes * (60)
          hours   = minutes / (60)
          days    = minutes / (60*24)

          now     = Time.at(seconds)

          attributes = {}
          attributes["epoch_seconds"] = seconds
          attributes["epoch_minutes"] = minutes
          attributes["epoch_hours"]   = hours
          attributes["epoch_days"]    = days

          attributes["minute"] = now.min
          attributes["hour"]   = now.hour
          attributes["day"]    = now.day
          attributes["month"]  = now.month
          attributes["year"]   = now.year
          attributes["yday"]   = now.yday
          attributes["wday"]   = now.wday

          ResqueBus.publish("heartbeat_minutes", attributes)
          set_saved_minute!(minutes)
        end

        unlock!
      end
    end

  end
end