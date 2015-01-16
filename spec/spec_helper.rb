require 'timecop'
require 'resque-bus'
require 'resque'
require 'resque/scheduler'

module QueueBus
  class Runner
    def self.value
      @value ||= 0
    end

    def self.attributes
      @attributes
    end

    def self.run(attrs)
      @value ||= 0
      @value += 1
      @attributes = attrs
    end

    def self.reset
      @value = nil
      @attributes = nil
    end
  end

  class Runner1 < Runner
  end

  class Runner2 < Runner
  end
end

def perform_next_job(worker, &block)
  return unless job = @worker.reserve
  @worker.perform(job, &block)
  @worker.done_working
end

def test_sub(event_name, queue="default")
  matcher = {"bus_event_type" => event_name}
  QueueBus::Subscription.new(queue, event_name, "::QueueBus::Rider", matcher, nil)
end

def test_list(*args)
  out = QueueBus::SubscriptionList.new
  args.each do |sub|
    out.add(sub)
  end
  out
end

# Resque::Scheduler.mute = true

def reset_test_adapter
  QueueBus.send(:reset)
  QueueBus.adapter = QueueBus::Adapters::Resque.new
end


RSpec.configure do |config|
  config.mock_framework = :rspec

  config.before(:each) do
    reset_test_adapter
  end
  config.after(:each) do
    begin
      QueueBus.redis { |redis| redis.flushall }
    rescue
    end
    QueueBus.send(:reset)
    QueueBus::Runner1.reset
    QueueBus::Runner2.reset
  end
end
