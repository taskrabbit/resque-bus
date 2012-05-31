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
      
      ResqueBus.log_worker("Driver running: #{event_type} #{attributes.inspect}")

      queue_matches(event_type).each do |tuple|
        match, queue_name = tuple
        ResqueBus.log_worker("  ...sending to #{queue_name} queue because of subscription: #{match}")
        
        bus_attr = {"bus_event_type" => event_type, "bus_driven_at" => Time.now.to_i, "bus_rider_queue" => queue_name}
        ResqueBus.enqueue_to(queue_name, Rider, match, bus_attr.merge(attributes || {}))
      end
    end

  end
end