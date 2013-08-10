require 'spec_helper'

class SubscriberTest1
  include ResqueBus::Subscriber
  @queue = "myqueue"
  
  application :my_thing
  subscribe :thing_filter, :x => "y"
  subscribe :event_sub
  
  def event_sub(attributes)
    ResqueBus::Runner1.run(attributes)
  end
  
  def thing_filter(attributes)
    ResqueBus::Runner2.run(attributes)
  end
end

class SubscriberTest2
  include ResqueBus::Subscriber
  application :test2
  subscribe :test2,  "value" => :present
  transform :make_an_int
  
  def self.make_an_int(attributes)
    attributes["value"].to_s.length
  end
  
  def test2(int)
    ResqueBus::Runner1.run("transformed"=>int)
  end
end

module SubModule
  class SubscriberTest3
    include ResqueBus::Subscriber
    
    subscribe_queue :sub_queue1, :test3, :bus_event_type => "the_event"
    subscribe_queue :sub_queue2, :the_event
    subscribe :other, :bus_event_type => "other_event"
    
    def test3(attributes)
      ResqueBus::Runner1.run(attributes)
    end
    
    def the_event(attributes)
      ResqueBus::Runner2.run(attributes)
    end
  end
  
  class SubscriberTest4
    include ResqueBus::Subscriber
    
    subscribe_queue :sub_queue1, :test4
  end
end

module ResqueBus
  describe Subscriber do
    let(:attributes) { {"x" => "y"} }
    let(:bus_attrs) { {"bus_driven_at" => Time.now.to_i} }
    
    before(:each) do
      ResqueBus::TaskManager.new(false).subscribe!
    end
    
    it "should have the application" do
      SubscriberTest1.app_key.should == "my_thing"
      SubModule::SubscriberTest3.app_key.should == "sub_module"
      SubModule::SubscriberTest4.app_key.should == "sub_module"
    end
    
    it "should be able to transform the attributes" do
      dispatcher = ResqueBus.dispatcher_by_key("test2")
      all = dispatcher.subscriptions.all
      all.size.should == 1

      sub = all.first
      sub.queue_name.should == "default"
      sub.class_name.should == "SubscriberTest2"
      sub.key.should == "SubscriberTest2.test2"
      sub.matcher.filters.should == {"value"=>"bus_special_value_present"}

      Driver.perform(attributes.merge("bus_event_type" => "something2", "value"=>"nice"))

      hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
      hash["class"].should == "SubscriberTest2"
      hash["args"].should == [ {"bus_rider_app_key"=>"test2", "bus_rider_sub_key"=>"SubscriberTest2.test2", "bus_rider_queue" => "default", "bus_rider_class_name"=>"SubscriberTest2",
                               "bus_event_type" => "something2", "value"=>"nice", "x"=>"y"}.merge(bus_attrs) ]
                               
      Runner1.value.should == 0
      Runner2.value.should == 0
      Util.constantize(hash["class"]).perform(*hash["args"])
      Runner1.value.should == 1
      Runner2.value.should == 0
      
      Runner1.attributes.should == {"transformed" => 4}
      
      
      Driver.perform(attributes.merge("bus_event_type" => "something2", "value"=>"12"))
      
      hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
      hash["class"].should == "SubscriberTest2"
      hash["args"].should == [ {"bus_rider_app_key"=>"test2", "bus_rider_sub_key"=>"SubscriberTest2.test2", "bus_rider_queue" => "default", "bus_rider_class_name"=>"SubscriberTest2",
                               "bus_event_type" => "something2", "value"=>"12", "x"=>"y"}.merge(bus_attrs) ]
                               
      Runner1.value.should == 1
      Runner2.value.should == 0
      Util.constantize(hash["class"]).perform(*hash["args"])
      Runner1.value.should == 2
      Runner2.value.should == 0
      
      Runner1.attributes.should == {"transformed" => 2}
    end
      
    
    it "should put in a different queue" do
      dispatcher = ResqueBus.dispatcher_by_key("sub_module")
      all = dispatcher.subscriptions.all
      all.size.should == 4
      
      sub = all.select{ |s| s.key == "SubModule::SubscriberTest3.test3"}.first
      sub.queue_name.should == "sub_queue1"
      sub.class_name.should == "SubModule::SubscriberTest3"
      sub.key.should == "SubModule::SubscriberTest3.test3"
      sub.matcher.filters.should == {"bus_event_type"=>"the_event"}
      
      sub = all.select{ |s| s.key == "SubModule::SubscriberTest3.the_event"}.first
      sub.queue_name.should == "sub_queue2"
      sub.class_name.should == "SubModule::SubscriberTest3"
      sub.key.should == "SubModule::SubscriberTest3.the_event"
      sub.matcher.filters.should == {"bus_event_type"=>"the_event"}
      
      sub = all.select{ |s| s.key == "SubModule::SubscriberTest3.other"}.first
      sub.queue_name.should == "default"
      sub.class_name.should == "SubModule::SubscriberTest3"
      sub.key.should == "SubModule::SubscriberTest3.other"
      sub.matcher.filters.should == {"bus_event_type"=>"other_event"}
      
      sub = all.select{ |s| s.key == "SubModule::SubscriberTest4.test4"}.first
      sub.queue_name.should == "sub_queue1"
      sub.class_name.should == "SubModule::SubscriberTest4"
      sub.key.should == "SubModule::SubscriberTest4.test4"
      sub.matcher.filters.should == {"bus_event_type"=>"test4"}
      
      Driver.perform(attributes.merge("bus_event_type" => "the_event"))

      hash = JSON.parse(ResqueBus.redis.lpop("queue:sub_queue1"))
      hash["class"].should == "SubModule::SubscriberTest3"
      hash["args"].should == [ {"bus_rider_app_key"=>"sub_module", "bus_rider_sub_key"=>"SubModule::SubscriberTest3.test3", "bus_rider_queue" => "sub_queue1", "bus_rider_class_name"=>"SubModule::SubscriberTest3",
                                "bus_event_type" => "the_event", "x" => "y"}.merge(bus_attrs) ]
                                
      Runner1.value.should == 0
      Runner2.value.should == 0
      Util.constantize(hash["class"]).perform(*hash["args"])
      Runner1.value.should == 1
      Runner2.value.should == 0
      
      hash = JSON.parse(ResqueBus.redis.lpop("queue:sub_queue2"))
      hash["class"].should == "SubModule::SubscriberTest3"
      hash["args"].should == [ {"bus_rider_app_key"=>"sub_module", "bus_rider_sub_key"=>"SubModule::SubscriberTest3.the_event", "bus_rider_queue" => "sub_queue2", "bus_rider_class_name"=>"SubModule::SubscriberTest3",
                                "bus_event_type" => "the_event", "x" => "y"}.merge(bus_attrs) ]
                                
      Runner1.value.should == 1
      Runner2.value.should == 0
      Util.constantize(hash["class"]).perform(*hash["args"])
      Runner1.value.should == 1
      Runner2.value.should == 1
    end
    
    it "should subscribe to default and attributes" do
      dispatcher = ResqueBus.dispatcher_by_key("my_thing")
      all = dispatcher.subscriptions.all
      
      sub = all.select{ |s| s.key == "SubscriberTest1.event_sub"}.first
      sub.queue_name.should == "myqueue"
      sub.class_name.should == "SubscriberTest1"
      sub.key.should == "SubscriberTest1.event_sub"
      sub.matcher.filters.should == {"bus_event_type"=>"event_sub"}
      
      sub = all.select{ |s| s.key == "SubscriberTest1.thing_filter"}.first
      sub.queue_name.should == "myqueue"
      sub.class_name.should == "SubscriberTest1"
      sub.key.should == "SubscriberTest1.thing_filter"
      sub.matcher.filters.should == {"x"=>"y"}
      
      Driver.perform(attributes.merge("bus_event_type" => "event_sub"))
      ResqueBus.redis.smembers("queues").should =~ ["myqueue"]

      hash = JSON.parse(ResqueBus.redis.lpop("queue:myqueue"))
      hash["class"].should == "SubscriberTest1"
      hash["args"].should == [ {"bus_rider_app_key"=>"my_thing", "bus_rider_sub_key"=>"SubscriberTest1.event_sub", "bus_rider_queue" => "myqueue", "bus_rider_class_name"=>"SubscriberTest1",
                                "bus_event_type" => "event_sub", "x" => "y"}.merge(bus_attrs) ]
                                
      Runner1.value.should == 0
      Runner2.value.should == 0
      Util.constantize(hash["class"]).perform(*hash["args"])
      Runner1.value.should == 1
      Runner2.value.should == 0
      
      hash = JSON.parse(ResqueBus.redis.lpop("queue:myqueue"))
      hash["class"].should == "SubscriberTest1"
      hash["args"].should == [ {"bus_rider_app_key"=>"my_thing", "bus_rider_sub_key"=>"SubscriberTest1.thing_filter", "bus_rider_queue" => "myqueue", "bus_rider_class_name"=>"SubscriberTest1",
                                "bus_event_type" => "event_sub", "x" => "y"}.merge(bus_attrs) ]
                                
      Runner1.value.should == 1
      Runner2.value.should == 0
      Util.constantize(hash["class"]).perform(*hash["args"])
      Runner1.value.should == 1
      Runner2.value.should == 1
      
      Driver.perform(attributes.merge("bus_event_type" => "event_sub_other"))
      ResqueBus.redis.smembers("queues").should =~ ["myqueue"]
      
      hash = JSON.parse(ResqueBus.redis.lpop("queue:myqueue"))
      hash["class"].should == "SubscriberTest1"
      hash["args"].should == [ {"bus_rider_app_key"=>"my_thing", "bus_rider_sub_key"=>"SubscriberTest1.thing_filter", "bus_rider_queue" => "myqueue", "bus_rider_class_name"=>"SubscriberTest1",
                                "bus_event_type" => "event_sub_other", "x" => "y"}.merge(bus_attrs) ]
                                
      Runner1.value.should == 1
      Runner2.value.should == 1
      Util.constantize(hash["class"]).perform(*hash["args"])
      Runner1.value.should == 1
      Runner2.value.should == 2
      
      Driver.perform({"x"=>"z"}.merge("bus_event_type" => "event_sub_other"))
      ResqueBus.redis.smembers("queues").should =~ ["myqueue"]
      
      ResqueBus.redis.lpop("queue:myqueue").should be_nil
    end
  end
end