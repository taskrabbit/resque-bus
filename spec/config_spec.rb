require 'spec_helper'

module QueueBus
  module Adapters
    class TestOne

    end
  end
end

describe "QueueBus config" do
  it "should set the default app key" do
    QueueBus.default_app_key.should == nil

    QueueBus.default_app_key = "my_app"
    QueueBus.default_app_key.should == "my_app"

    QueueBus.default_app_key = "something here"
    QueueBus.default_app_key.should == "something_here"
  end

  it "should set the default queue" do
    QueueBus.default_queue.should == nil

    QueueBus.default_queue = "my_queue"
    QueueBus.default_queue.should == "my_queue"
  end

  it "should set the local mode" do
    QueueBus.local_mode.should == nil
    QueueBus.local_mode = :standalone
    QueueBus.local_mode.should == :standalone
  end

  it "should set the hostname" do
    QueueBus.hostname.should_not == nil
    QueueBus.hostname = "whatever"
    QueueBus.hostname.should == "whatever"
  end

  it "should set before_publish callback" do
    QueueBus.before_publish = lambda {|attributes| 42 }
    QueueBus.before_publish_callback({}).should == 42
  end


  it "should use the default Redis connection" do
    QueueBus.redis { |redis| redis }.should_not eq(nil)
  end

  it "should default to given adapter" do
    QueueBus.adapter.is_a?(adapter_under_test_class).should == true

    # and should raise if already set
    lambda {
      QueueBus.adapter = :data
    }.should raise_error
  end

  context "with a fresh load" do
    before(:each) do
      QueueBus.send(:reset)
    end

    it "should be able to be set to resque" do
      QueueBus.adapter = adapter_under_test_symbol
      QueueBus.adapter.is_a?(adapter_under_test_class).should == true

      # and should raise if already set
      lambda {
        QueueBus.adapter = :data
      }.should raise_error
    end

    it "should be able to be set to something else" do

      QueueBus.adapter = :test_one
      QueueBus.adapter.is_a?(QueueBus::Adapters::TestOne).should == true
    end
  end


end
