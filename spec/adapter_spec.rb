require 'spec_helper'

describe "adapter is set" do
  it "should call it's enabled! method on init" do
    QueueBus.send(:reset)
    adapter_under_test_class.any_instance.should_receive(:enabled!)
    instance = adapter_under_test_class.new
    QueueBus.send(:reset)
  end

  it "should be defaulting to Data from spec_helper" do
    QueueBus.adapter.is_a?(adapter_under_test_class).should == true
  end
end
