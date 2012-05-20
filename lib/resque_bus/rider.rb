module ResqueBus
  # queue'd in each
  class Rider
    
    def self.perform(match, attributes = {})
      raise "No event type match passed" if match == nil || match == ""
      attributes ||= {}
      
      # (now running with the real app that subscribed)
      # find the subscription from Routes for the event 
      # and execute the block with the remaining attributes
    end
  end
end