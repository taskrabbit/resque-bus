require 'spec_helper'

module ResqueBus
  module Adapters
    class TestOne

    end
  end
end

describe "ResqueBus config" do
  it "should set the default app key" do
    ResqueBus.default_app_key.should == nil

    ResqueBus.default_app_key = "my_app"
    ResqueBus.default_app_key.should == "my_app"

    ResqueBus.default_app_key = "something here"
    ResqueBus.default_app_key.should == "something_here"
  end

  it "should set the default queue" do
    ResqueBus.default_queue.should == nil

    ResqueBus.default_queue = "my_queue"
    ResqueBus.default_queue.should == "my_queue"
  end

  it "should set the local mode" do
    ResqueBus.local_mode.should == nil
    ResqueBus.local_mode = :standalone
    ResqueBus.local_mode.should == :standalone
  end

  it "should set the hostname" do
    ResqueBus.hostname.should_not == nil
    ResqueBus.hostname = "whatever"
    ResqueBus.hostname.should == "whatever"
  end

  it "should set before_publish callback" do
    ResqueBus.before_publish = lambda {|attributes| 42 }
    ResqueBus.before_publish_callback({}).should == 42
  end


  it "should use the default Resque connection" do
    ResqueBus.redis { |redis| redis }.should == Resque.redis
  end

  it "should default to resque adapter" do
    ResqueBus.adapter.is_a?(ResqueBus::Adapters::Resque).should == true

    # and should raise if already set
    lambda {
      ResqueBus.adapter = :resque
    }.should raise_error
  end

  it "should be able to be set to resque" do
    ResqueBus.adapter = :resque
    ResqueBus.adapter.is_a?(ResqueBus::Adapters::Resque).should == true

    # and should raise if already set
    lambda {
      ResqueBus.adapter = :resque
    }.should raise_error
  end

  it "should be able to be set to something else" do
    ResqueBus.adapter = :test_one
    ResqueBus.adapter.is_a?(ResqueBus::Adapters::TestOne).should == true
  end


end
