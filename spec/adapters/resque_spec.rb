require 'spec_helper'

module ResqueBus
  describe Adapters::Resque do
    it "should call it's enabled! method on init" do
      ResqueBus::Adapters::Resque.any_instance.should_receive(:enabled!)
      instance = ResqueBus::Adapters::Resque.new
      ResqueBus.adapter = instance # prevents making a new one and causing and error in :after
    end
  end
end
