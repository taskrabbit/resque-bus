module ResqueBus
  # fans out an event to multiple queues
  class Driver
    
    def self.queue_matches(event_type)
      out = []
      Application.all.each do |app|
        app.event_matches(event_type).each do |match, queue_name|
          out << [match, queue_name]
        end
      end
      out
    end
    
    def self.perform(event_type, attributes = {})
      raise "No event type passed" if event_type == nil || event_type == ""
      attributes ||= {}
      
      
      queue_matches(event_type).each do |tuple|
        match, queue_name = tuple
        enqueue_to(queue_name, Rider, event_type, attributes)
      end
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