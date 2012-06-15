module ResqueBus
  # only process local queues
  class Local

    def self.perform(event_type, attributes = {})
      raise "No event type passed" if event_type == nil || event_type == ""

      ResqueBus.log_worker("Local running: #{event_type} #{attributes.inspect}")

      ResqueBus.application.event_matches(event_type).each do |match, queue_name|
        bus_attr = {"bus_event_type" => event_type, "bus_driven_at" => Time.now.to_i, "bus_rider_queue" => queue_name}
        if ResqueBus.local_mode == :standalone
          ResqueBus.enqueue_to(queue_name, Rider, match, bus_attr.merge(attributes || {}))
        # defaults to inline mode
        else ResqueBus.local_mode == :inline
          ResqueBus.dispatcher.execute(match, bus_attr.merge(attributes || {} ))
        end
      end
    end

  end
end
