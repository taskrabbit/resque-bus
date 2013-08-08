module ResqueBus
  # fans out an event to multiple queues
  class Driver

    def self.queue_matches(attributes)
      out = []
      Application.all.each do |app|
        tuples = app.subscription_tuples(attributes)
        out.concat(tuples)
      end
      out
    end

    def self.perform(attributes={})
      raise "No attribiutes passed" if attributes.empty?

      ResqueBus.log_worker("Driver running: #{attributes.inspect}")

      queue_matches(attributes).each do |tuple|
        key, queue_name = tuple
        ResqueBus.log_worker("  ...sending to #{queue_name} queue because of subscription: #{key}")
        
        bus_attr = {"bus_driven_at" => Time.now.to_i, "bus_rider_queue" => queue_name}
        ResqueBus.enqueue_to(queue_name, Rider, key, bus_attr.merge(attributes || {}))
      end
    end

  end
end
