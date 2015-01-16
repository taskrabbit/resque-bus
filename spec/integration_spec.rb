require 'spec_helper'

module QueueBus
  describe "Integration" do
    it "should round trip attributes" do      
      write1 = Subscription.new("default", "key1", "MyClass1", {"bus_event_type" => "event_one"})
      write2 = Subscription.new("else_ok", "key2", "MyClass2", {"bus_event_type" => /^[ab]here/})  #regex
    
      write1.matches?("bus_event_type" => "event_one").should  == true
      write1.matches?("bus_event_type" => "event_one1").should == false
      write1.matches?("bus_event_type" => "aevent_one").should == false
      
      write2.matches?("bus_event_type" => "ahere").should == true
      write2.matches?("bus_event_type" => "bhere").should == true
      write2.matches?("bus_event_type" => "qhere").should == false
      write2.matches?("bus_event_type" => "abhere").should == false
      write2.matches?("bus_event_type" => "[ab]here").should == false
    
      write = SubscriptionList.new
      write.add(write1)
      write.add(write2)
    
      app = Application.new("test")
      app.subscribe(write)
    
      reset_test_adapter  # reset to make sure we read from redis
      app = Application.new("test")
      read = app.send(:subscriptions)
    
      read.size.should == 2
      read1 = read.key("key1")
      read2 = read.key("key2")
      read1.should_not be_nil
      read2.should_not be_nil
      
      read1.queue_name.should == "default"
      read1.class_name.should == "MyClass1"
      read2.queue_name.should == "else_ok"
      read2.class_name.should == "MyClass2"
      
      read1.matches?("bus_event_type" => "event_one").should  == true
      read1.matches?("bus_event_type" => "event_one1").should == false
      read1.matches?("bus_event_type" => "aevent_one").should == false
      
      read2.matches?("bus_event_type" => "ahere").should == true
      read2.matches?("bus_event_type" => "bhere").should == true
      read2.matches?("bus_event_type" => "qhere").should == false
      read2.matches?("bus_event_type" => "abhere").should == false
      read2.matches?("bus_event_type" => "[ab]here").should == false
      
    end
  end
end