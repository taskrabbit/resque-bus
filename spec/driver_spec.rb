require 'spec_helper'

module ResqueBus
  describe Driver do
    before(:each) do
      ResqueBus.subscribe("app1", ["event1", "event2", "event3"])
      ResqueBus.subscribe("app2", {"event2" => "other", "event4" => "more"})
      ResqueBus.subscribe("app3", ["event[45]", "event5", "event6"])
      Timecop.freeze
    end
    after(:each) do
      Timecop.return
    end
    
    let(:bus_attrs) { {"bus_driven_at" => Time.now.to_i} }
    
    describe ".queue_matches" do
      it "return empty array when none" do
        Driver.queue_matches("else").should == []
        Driver.queue_matches("event").should == []
      end
      it "should return a match" do
        Driver.queue_matches("event1").should =~ [["event1", "app1_default"]]
        Driver.queue_matches("event6").should =~ [["event6", "app3_default"]]
      end
      it "should match multiple apps" do
        Driver.queue_matches("event2").should =~ [["event2", "app1_default"], ["event2", "app2_other"]]
      end
      it "should match multiple apps with patterns" do
        Driver.queue_matches("event4").should =~ [["event[45]", "app3_default"], ["event4", "app2_more"]]
      end
      it "should match multiple events in same app" do
        Driver.queue_matches("event5").should =~ [["event[45]", "app3_default"], ["event5", "app3_default"]]
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
        Driver.perform("else", attributes)
        ResqueBus.redis.smembers("queues").should == []
      end
      
      it "should queue up the riders in redis" do
        ResqueBus.redis.lpop("queue:app1_default").should be_nil
        Driver.perform("event1", attributes)
        ResqueBus.redis.smembers("queues").should =~ ["app1_default"]

        hash = JSON.parse(ResqueBus.redis.lpop("queue:app1_default"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"].should == [ "event1", {"x" => "y", "bus_event_type" => "event1", "bus_rider_queue" => "app1_default"}.merge(bus_attrs) ]
      end
      
      it "should queue up to multiple" do
        Driver.perform("event4", attributes)
        ResqueBus.redis.smembers("queues").should =~ ["app3_default", "app2_more"]
        
        ResqueBus.redis.lpop("queue:app1_default").should be_nil
        ResqueBus.redis.lpop("queue:app2_default").should be_nil

        hash = JSON.parse(ResqueBus.redis.lpop("queue:app2_more"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"].should == [ "event4", {"x" => "y", "bus_event_type" => "event4", "bus_rider_queue" => "app2_more"}.merge(bus_attrs) ]
        
        hash = JSON.parse(ResqueBus.redis.lpop("queue:app3_default"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"].should == [ "event[45]", {"x" => "y", "bus_event_type" => "event4", "bus_rider_queue" => "app3_default"}.merge(bus_attrs) ]
      end
      
      it "should queue up to the same" do
        Driver.perform("event5", attributes)
        ResqueBus.redis.smembers("queues").should =~ ["app3_default"]
        
        ResqueBus.redis.lpop("queue:app1_default").should be_nil
        ResqueBus.redis.lpop("queue:app2_default").should be_nil
        ResqueBus.redis.lpop("queue:app2_more").should be_nil
        ResqueBus.redis.lpop("queue:app2_other").should be_nil

        ResqueBus.redis.llen("queue:app3_default").should == 2
        
        hash = JSON.parse(ResqueBus.redis.lpop("queue:app3_default"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"][1].should == {"x" => "y", "bus_event_type" => "event5", "bus_rider_queue" => "app3_default"}.merge(bus_attrs)
        first = hash["args"][0]
        
        hash = JSON.parse(ResqueBus.redis.lpop("queue:app3_default"))
        hash["class"].should == "ResqueBus::Rider"
        hash["args"][1].should == {"x" => "y", "bus_event_type" => "event5", "bus_rider_queue" => "app3_default"}.merge(bus_attrs)
        second = hash["args"][0]
        
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