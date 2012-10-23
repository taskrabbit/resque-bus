module ResqueBus
  # only process local queues
  class Local

    def self.perform(event_type, attributes = {})
      raise "No event type passed" if event_type == nil || event_type == ""

      ResqueBus.log_worker("Local running: #{event_type} #{attributes.inspect}")

      # looking for subscriptions, not queues
      subscription_matches(event_type).each do |sub|
        bus_attr = {"bus_event_type" => event_type, "bus_driven_at" => Time.now.to_i } # "bus_rider_queue" => queue_name}
        to_publish = bus_attr.merge(attributes || {})
        if ResqueBus.local_mode == :standalone
          queue_name =  "#{ResqueBus.application.app_key}_#{sub.queue_name}"
          ResqueBus.enqueue_to(queue_name, Rider, sub.key, to_publish)
        # defaults to inline mode
        else ResqueBus.local_mode == :inline
          sub.execute!(to_publish)
        end
      end
    end

    # looking directly at subscriptions loaded into dispatcher
    # so we don't need redis server up
    def self.subscription_matches(event_type)
      ResqueBus.dispatcher.subscription_matches(event_type)
    end

  end
end
