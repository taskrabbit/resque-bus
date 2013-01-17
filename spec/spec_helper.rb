require 'rubygems'
require 'bundler/setup'
require 'timecop'

require 'resque-bus'

module ResqueBus
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
  ResqueBus::Subscription.new(queue, event_name, {}, nil)
end

def test_list(*args)
  out = ResqueBus::SubscriptionList.new
  args.each do |sub|
    out.add(sub)
  end
  out
end


Resque::Scheduler.mute = true

RSpec.configure do |config|
  config.mock_framework = :rspec
  
  config.before(:each) do
    ResqueBus.send(:reset)
    ResqueBus.app_key = "test"
  end
  config.after(:each) do
    begin
      ResqueBus.redis.flushall
    rescue
    end
    ResqueBus.send(:reset)
    ResqueBus::Runner1.reset
    ResqueBus::Runner2.reset
  end
end

ResqueBus.redis.namespace = "resquebus_test"
