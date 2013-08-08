require 'spec_helper'

module ResqueBus
  describe Subscription do
    it "should normalize the queue name" do
      Subscription.new("test", "my_event", {}, nil).queue_name.should == "test"
      Subscription.new("tes t", "my_event", {}, nil).queue_name.should == "tes_t"
      Subscription.new("t%s", "my_event", {}, nil).queue_name.should == "t_s"
    end
    
    describe ".register" do
      it "should take in args from dispatcher" do
        executor = Proc.new { |attributes| }
        sub = Subscription.register("queue_name", "mykey", {"bus_event_type" => "my_event"}, executor)
        sub.send(:executor).should == executor
        sub.matcher.filters.should == {"bus_event_type" => "my_event"}
        sub.queue_name.should == "queue_name"
        sub.key.should == "mykey"
      end
    end
    
    describe "#execute!" do
      it "should call the executor with the attributes" do
        exec = Object.new
        exec.should_receive(:call)
        
        sub = Subscription.new("x", "y", {}, exec)
        sub.execute!({"ok" => true})
      end
    end
    
    describe "#to_redis" do
      it "should return what to store for this subscription" do
        sub = Subscription.new("queue_one", "xyz", {"bus_event_type" => "my_event"}, nil)
        sub.to_redis.should == {"queue_name" => "queue_one", "key" => "xyz", "matcher" => {"bus_event_type" => "my_event"}}
      end
    end
    
    describe "#matches?" do
      it "should do pattern stuff" do
        Subscription.new("x", "id", {"bus_event_type" => "one"}).matches?("bus_event_type" => "one").should == true
        Subscription.new("x", "id", {"bus_event_type" => "one"}).matches?("bus_event_type" => "onex").should == false
        Subscription.new("x", "id", {"bus_event_type" => "^one.*$"}).matches?("bus_event_type" => "onex").should == true
        Subscription.new("x", "id", {"bus_event_type" => "one.*"}).matches?("bus_event_type" => "onex").should == true
        Subscription.new("x", "id", {"bus_event_type" => "one.?"}).matches?("bus_event_type" => "onex").should == true
        Subscription.new("x", "id", {"bus_event_type" => "one.?"}).matches?("bus_event_type" => "one").should == true
        Subscription.new("x", "id", {"bus_event_type" => "\\"}).matches?("bus_event_type" => "one").should == false
      end
    end
    
  end
end