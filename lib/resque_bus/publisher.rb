module ResqueBus
  # publishes on a delay
  class Publisher
    class << self
      def perform(*args)
        if args.size > 1
          event_type = args.first
          attributes = args.last
        else
          attributes = args.first
          event_type = attributes["bus_event_type"]
        end
        ResqueBus.log_worker("Publisher running: #{event_type} - #{attributes.inspect}")
        ResqueBus.publish(event_type, attributes)
      end
    end

  end
end