require 'resque-bus'
require 'resque'
require 'resque/scheduler'

def reset_test_adapter
  QueueBus.send(:reset)
  QueueBus.adapter = QueueBus::Adapters::Resque.new
end

def adapter_under_test_class
  QueueBus::Adapters::Resque
end

def adapter_under_test_symbol
  :resque
end

def perform_next_job(worker, &block)
  return unless job = worker.reserve
  worker.perform(job, &block)
  worker.done_working
end

