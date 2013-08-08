require 'resque-retry'

module ResqueBus
  # queue'd in each
  class Rider
    extend Resque::Plugins::ExponentialBackoff
    
    def self.perform(key, attributes = {})
      raise "No subscription key passed" if key == nil || key == ""
      attributes ||= {}
      
      ResqueBus.log_worker("Rider received: #{key} #{attributes.inspect}")
      
      # attributes that should be available
      # attributes["bus_event_type"]
      # attributes["bus_app_key"]
      # attributes["bus_published_at"]
      # attributes["bus_driven_at"]
      
      # allow the real Reqsue to be used inside the callback while in a worker
      Resque.redis = ResqueBus.original_redis if ResqueBus.original_redis
      
      # (now running with the real app that subscribed)
      ResqueBus.dispatcher.execute(key, attributes.merge("bus_executed_at" => Time.now.to_i))
    ensure
      # put this back if running in the thread
      Resque.redis = ResqueBus.redis if ResqueBus.original_redis
    end
    
    # @failure_hooks_already_ran on https://github.com/defunkt/resque/tree/1-x-stable
    # to prevent running twice
    def self.queue
      @my_queue
    end
    
    def self.on_failure_aaa(exception, *args)
      # note: sorted alphabetically
      # queue needs to be set for rety to work (know what queue in Requeue.class_to_queue)
      @my_queue = args[1]["bus_rider_queue"]
    end
    
    def self.on_failure_zzz(exception, *args)
      # note: sorted alphabetically
      @my_queue = nil
    end
    
  end
end