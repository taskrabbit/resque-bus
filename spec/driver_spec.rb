require 'spec_helper'

module ResqueBus
  describe Driver do
    before(:each) do
      Application.new("app1").subscribe(test_list(test_sub("event1"), test_sub("event2"), test_sub("event3")))
      Application.new("app2").subscribe(test_list(test_sub("event2","other"), test_sub("event4", "more")))
      Application.new("app3").subscribe(test_list(test_sub("event[45]"), test_sub("event5"), test_sub("event6")))
      Timecop.freeze
    end
    after(:each) do
      Timecop.return
    end
    
    let(:bus_attrs) { {"bus_driven_at" => Time.now.to_i} }
    
    describe ".queue_matches" do
      it "return empty array when none" do
        Driver.queue_matches("bus_event_type" => "else").should == []
        Driver.queue_matches("bus_event_type" => "event").should == []
      end
      it "should return a match" do
        Driver.queue_matches("bus_event_type" => "event1").should =~ [["app1", "event1", "default"]]
        Driver.queue_matches("bus_event_type" => "event6").should =~ [["app3", "event6", "default"]]
      end
      it "should match multiple apps" do
        Driver.queue_matches("bus_event_type" => "event2").should =~ [["app1", "event2", "default"], ["app2", "event2", "other"]]
      end
      it "should match multiple apps with patterns" do
        Driver.queue_matches("bus_event_type" => "event4").should =~ [["app3", "event[45]", "default"], ["app2", "event4", "more"]]
      end
      it "should match multiple events in same app" do
        Driver.queue_matches("bus_event_type" => "event5").should =~ [["app3", "event[45]", "default"], ["app3", "event5", "default"]]
      end
    end
    
    describe ".peform" do
      let(:attributes) { {"x" => "y"} }
      
      before(:each) do
        ResqueBus.redis.smembers("queues").should == []
        ResqueBus.redis.lpop("queue:app1_default").should be_nil
        ResqueBus.redis.lpop("queue:app2_default").should be_nil
        ResqueBus.redis.lpop("queue:app3_default").should be_nil
      end
      
      it "should do nothing when empty" do
        Driver.perform(attributes.merge("bus_event_type" => "else"))
        ResqueBus.redis.smembers("queues").should == []
      end
      
      it "should queue up the riders in redis" do
        ResqueBus.redis.lpop("queue:app1_default").should be_nil
        Driver.perform(attributes.merge("bus_event_type" => "event1"))
        ResqueBus.redis.smembers("queues").should =~ ["default"]

        hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"].should == [ "app1", "event1", {"x" => "y", "bus_event_type" => "event1", "bus_rider_queue" => "default"}.merge(bus_attrs) ]
      end
      
      it "should queue up to multiple" do
        Driver.perform(attributes.merge("bus_event_type" => "event4"))
        ResqueBus.redis.smembers("queues").should =~ ["default", "more"]

        hash = JSON.parse(ResqueBus.redis.lpop("queue:more"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"].should == [ "app2", "event4", {"x" => "y", "bus_event_type" => "event4", "bus_rider_queue" => "more"}.merge(bus_attrs) ]
        
        hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"].should == [ "app3", "event[45]", {"x" => "y", "bus_event_type" => "event4", "bus_rider_queue" => "default"}.merge(bus_attrs) ]
      end
      
      it "should queue up to the same" do
        Driver.perform(attributes.merge("bus_event_type" => "event5"))
        ResqueBus.redis.smembers("queues").should =~ ["default"]

        ResqueBus.redis.llen("queue:default").should == 2
        
        hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"][0].should == "app3"
        hash["args"][2].should == {"x" => "y", "bus_event_type" => "event5", "bus_rider_queue" => "default"}.merge(bus_attrs)
        first = hash["args"][1]
        
        hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"][0].should == "app3"
        hash["args"][2].should == {"x" => "y", "bus_event_type" => "event5", "bus_rider_queue" => "default"}.merge(bus_attrs)
        second = hash["args"][1]
        
        if first == "event[45]"
          second.should == "event5"
        else
          first.should == "event5"
          second.should == "event[45]"
        end
      end
    end
  end
end