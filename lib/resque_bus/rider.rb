module ResqueBus
  # queue'd in each
  class Rider
    
    def self.perform(match, attributes = {})
      raise "No event type match passed" if match == nil || match == ""
      attributes ||= {}
      
      # attributes that should be available
      # attributes["bus_event_type"]
      # attributes["bus_app_key"]
      # attributes["bus_published_at"]
      # attributes["bus_driven_at"]
      attributes["bus_executed_at"] = Time.now.to_i
      
      # (now running with the real app that subscribed)
      ResqueBus.dispatcher.execute(match, attributes)
    end
  end
end