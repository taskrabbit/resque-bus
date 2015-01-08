module ResqueBus
  # queue'd in each
  class Rider < ::ResqueBus::Worker
    class << self
      def perform(attributes = {})
        sub_key = attributes["bus_rider_sub_key"]
        app_key = attributes["bus_rider_app_key"]
        raise "No application key passed" if app_key.to_s == ""
        raise "No subcription key passed" if sub_key.to_s == ""
        
        attributes ||= {}
        
        ::ResqueBus.log_worker("Rider received: #{app_key} #{sub_key} #{attributes.inspect}")
        
        # attributes that should be available
        # attributes["bus_event_type"]
        # attributes["bus_app_key"]
        # attributes["bus_published_at"]
        # attributes["bus_driven_at"]
        
        # (now running with the real app that subscribed)
        ::ResqueBus.dispatcher_execute(app_key, sub_key, attributes.merge("bus_executed_at" => Time.now.to_i))
      end
    end
  end
end