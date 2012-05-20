module ResqueBus
  # fans out an event to multiple queues
  class Driver

    def self.perform(event_type, attributes = {})
      raise "No event type passed" if event_type == nil || event_type == ""
      attributes ||= {}
      
      #queues(event_type).each do |queue_name|
      #  enqueue_to(queue_name, Rider, event_type, attributes)
      #end
    end
    
    protected
    
    def self.normalize_key(name)
      #TODO: need to normalize app name
      name.to_s.gsub(/\W/, "_")
    end
    
    def self.default_queue
      "default"
    end
    
  end
end