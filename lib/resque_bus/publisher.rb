module ResqueBus
  # publishes on a delay
  class Publisher
    def self.perform(event_type, attributes = {})
      ResqueBus.log_worker("Publisher running: #{event_type} - #{attributes.inspect}")
      ResqueBus.publish(event_type, attributes)
    end
  end
end