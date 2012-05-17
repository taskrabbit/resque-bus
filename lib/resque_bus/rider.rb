module ResqueBus
  # queue'd in each
  class Rider
    
    def self.perform(event_type, attributes = {})
      raise "No event type passed" if event_type == nil || event_type == ""
      attributes ||= {}
      
      # (now running with the real app that subscribed)
      # find the subscription from Routes for the event 
      # and execute the block with the remaining attributes
    end
  end
end