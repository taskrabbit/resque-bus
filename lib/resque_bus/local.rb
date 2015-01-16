module ResqueBus
  # only process local queues
  class Local

    class << self
      def perform(attributes = {})
        if ::ResqueBus.local_mode == :suppress
          ::ResqueBus.log_worker("Suppressed: #{attributes.inspect}")
          return  # not doing anything
        end

        ::ResqueBus.log_worker("Local running: #{attributes.inspect}")

        # looking for subscriptions, not queues
        subscription_matches(attributes).each do |sub|
           bus_attr = {"bus_driven_at" => Time.now.to_i, "bus_rider_queue" => sub.queue_name, "bus_rider_app_key" => sub.app_key, "bus_rider_sub_key" => sub.key, "bus_rider_class_name" => sub.class_name}
          to_publish = bus_attr.merge(attributes || {})
          if ::ResqueBus.local_mode == :standalone
            ::ResqueBus.enqueue_to(sub.queue_name, sub.class_name, bus_attr.merge(attributes || {}))
          else  # defaults to inline mode
            sub.execute!(to_publish)
          end
        end
      end

      # looking directly at subscriptions loaded into dispatcher
      # so we don't need redis server up
      def subscription_matches(attributes)
        out = []
        ::ResqueBus.dispatchers.each do |dispatcher|
          out.concat(dispatcher.subscription_matches(attributes))
        end
        out
      end
    end

  end
end
