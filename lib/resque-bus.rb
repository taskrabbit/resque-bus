require "queue-bus"
require "resque_bus/adapter"
require "resque_bus/version"

QueueBus.adapter = QueueBus::Adapters::Resque.new
