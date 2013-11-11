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
    
    let(:bus_attrs) { {"bus_driven_at" => Time.now.to_i, "bus_rider_class_name"=>"::ResqueBus::Rider"} }
    
    describe ".subscription_matches" do
      it "return empty array when none" do
        Driver.subscription_matches("bus_event_type" => "else").collect{|s| [s.app_key, s.key, s.queue_name, s.class_name]}.should == []
        Driver.subscription_matches("bus_event_type" => "event").collect{|s| [s.app_key, s.key, s.queue_name, s.class_name]}.should == []
      end
      it "should return a match" do
        Driver.subscription_matches("bus_event_type" => "event1").collect{|s| [s.app_key, s.key, s.queue_name, s.class_name]}.should =~ [["app1", "event1", "default", "::ResqueBus::Rider"]]
        Driver.subscription_matches("bus_event_type" => "event6").collect{|s| [s.app_key, s.key, s.queue_name, s.class_name]}.should =~ [["app3", "event6", "default", "::ResqueBus::Rider"]]
      end
      it "should match multiple apps" do
        Driver.subscription_matches("bus_event_type" => "event2").collect{|s| [s.app_key, s.key, s.queue_name, s.class_name]}.should =~ [["app1", "event2", "default", "::ResqueBus::Rider"], ["app2", "event2", "other", "::ResqueBus::Rider"]]
      end
      it "should match multiple apps with patterns" do
        Driver.subscription_matches("bus_event_type" => "event4").collect{|s| [s.app_key, s.key, s.queue_name, s.class_name]}.should =~ [["app3", "event[45]", "default", "::ResqueBus::Rider"], ["app2", "event4", "more", "::ResqueBus::Rider"]]
      end
      it "should match multiple events in same app" do
        Driver.subscription_matches("bus_event_type" => "event5").collect{|s| [s.app_key, s.key, s.queue_name, s.class_name]}.should =~ [["app3", "event[45]", "default", "::ResqueBus::Rider"], ["app3", "event5", "default", "::ResqueBus::Rider"]]
      end
    end
    
    describe ".perform" do
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
        hash["class"].should == "::ResqueBus::Rider"
        hash["args"].should == [ {"bus_rider_app_key"=>"app1", "x" => "y", "bus_event_type" => "event1", "bus_rider_sub_key"=>"event1", "bus_rider_queue" => "default"}.merge(bus_attrs) ]
      end
      
      it "should queue up to multiple" do
        Driver.perform(attributes.merge("bus_event_type" => "event4"))
        ResqueBus.redis.smembers("queues").should =~ ["default", "more"]

        hash = JSON.parse(ResqueBus.redis.lpop("queue:more"))
        hash["class"].should == "::ResqueBus::Rider"
        hash["args"].should == [ {"bus_rider_app_key"=>"app2", "x" => "y", "bus_event_type" => "event4", "bus_rider_sub_key"=>"event4", "bus_rider_queue" => "more"}.merge(bus_attrs) ]
        
        hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
        hash["class"].should == "::ResqueBus::Rider"
        hash["args"].should == [ {"bus_rider_app_key"=>"app3", "x" => "y", "bus_event_type" => "event4", "bus_rider_sub_key"=>"event[45]", "bus_rider_queue" => "default"}.merge(bus_attrs) ]
      end
      
      it "should queue up to the same" do
        Driver.perform(attributes.merge("bus_event_type" => "event5"))
        ResqueBus.redis.smembers("queues").should =~ ["default"]

        ResqueBus.redis.llen("queue:default").should == 2
        
        hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
        hash["class"].should == "::ResqueBus::Rider"
        hash["args"][0].should == {"bus_rider_app_key"=>"app3", "x" => "y", "bus_event_type" => "event5", "bus_rider_sub_key"=>"event[45]", "bus_rider_queue" => "default"}.merge(bus_attrs)

        hash = JSON.parse(ResqueBus.redis.lpop("queue:default"))
        hash["class"].should == "::ResqueBus::Rider"
        hash["args"][0].should == {"bus_rider_app_key"=>"app3", "x" => "y", "bus_event_type" => "event5", "bus_rider_sub_key"=>"event5", "bus_rider_queue" => "default"}.merge(bus_attrs)
      end
    end
  end
end