# these can be in the queue from the new queue-bus version
module QueueBus
  class Worker

    def self.perform(json)
      attributes = ::Resque.decode(json)
      class_name = attributes["bus_class_proxy"]
      
      case class_name
      when "::QueueBus::Driver", "QueueBus::Driver"
        ResqueBus::Driver.perform(attributes)
      when "::QueueBus::Rider", "QueueBus::Rider"
        ResqueBus::Rider.perform(attributes)
      when "::QueueBus::Publisher", "QueueBus::Publisher"
        ResqueBus::Publisher.perform(attributes["bus_event_type"], attributes)
      else
        klass = ::ResqueBus::Util.constantize(class_name)
        klass.perform(attributes)
      end
    end
  end
end
