module ResqueBus
  # only process local queues
  class Local

    def self.perform(attributes = {})
      raise "No event type passed" if event_type == nil || event_type == ""

      ResqueBus.log_worker("Local running: #{event_type} #{attributes.inspect}")

      # looking for subscriptions, not queues
      
      subscription_matches(attributes).each do |sub|
        bus_attr = {"bus_driven_at" => Time.now.to_i }
        to_publish = bus_attr.merge(attributes || {})
        if ResqueBus.local_mode == :standalone
          queue_name = sub.queue_name
          ResqueBus.enqueue_to(queue_name, Rider, sub.key, to_publish)
        # defaults to inline mode
        else ResqueBus.local_mode == :inline
          sub.execute!(to_publish)
        end
      end
    end

    # looking directly at subscriptions loaded into dispatcher
    # so we don't need redis server up
    def self.subscription_matches(attributes)
      out = []
      ResqueBus.dispatchers.each do |dispatcher|
        out.concat(subscription_matches(attributes))
      end
      out
    end

  end
end
