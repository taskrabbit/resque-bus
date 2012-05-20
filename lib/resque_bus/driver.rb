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
        
        bus_attr = {:bus_event_type => event_type, :bus_driven_at => Time.now.to_i}
        ResqueBus.enqueue_to(queue_name, Rider, match, attributes.merge(bus_attr))
      end
    end

  end
end