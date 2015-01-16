require "queue-bus"
require "resque_bus/adapter"
require "resque_bus/version"

module ResqueBus

end

QueueBus.adapter = QueueBus::Adapters::Resque.new
