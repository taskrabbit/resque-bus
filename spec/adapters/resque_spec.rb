require 'spec_helper'

module QueueBus
  describe Adapters::Resque do
    it "should call it's enabled! method on init" do
      QueueBus.send(:reset)
      QueueBus::Adapters::Resque.any_instance.should_receive(:enabled!)
      instance = QueueBus::Adapters::Resque.new
      QueueBus.adapter = instance # prevents making a new one and causing and error in :after
    end

    it "should be defaulting to Resque from spec_helper" do
      QueueBus.adapter.is_a?(QueueBus::Adapters::Resque).should == true
    end
  end
end
