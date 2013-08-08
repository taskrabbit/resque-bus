require 'spec_helper'

module ResqueBus
  describe SubscriptionList do
    describe ".from_redis" do
      it "should return from attributes" do
        mult = {"event_one" => {"queue_name" => "default", "key" => "event_one", "matcher" => {"bus_event_type" => "event_one"}}, 
                "event_two" => {"queue_name" => "else",    "key" => "event_two", "matcher" => {"bus_event_type" => "event_two"}}}

        list = SubscriptionList.from_redis(mult)
        list.size.should == 2
        one = list.key("event_one")
        two = list.key("event_two")
        
        one.key.should == "event_one"
        one.key.should == "event_one"
        one.queue_name.should == "default"
        one.matcher.filters.should == {"bus_event_type" => "event_one"}
        
        two.key.should == "event_two"
        two.key.should == "event_two"
        two.queue_name.should == "else"
        two.matcher.filters.should == {"bus_event_type" => "event_two"}
      end
    end
    
    describe "#to_redis" do
      it "should generate what to store" do
        list = SubscriptionList.new
        list.add(Subscription.new("default", "key1", {"bus_event_type" => "event_one"}))
        list.add(Subscription.new("else_ok", "key2", {"bus_event_type" => "event_two"}))
        
        hash = list.to_redis
        hash.should == {  "key1" => {"queue_name" => "default", "key" => "key1", "matcher" => {"bus_event_type" => "event_one"}}, 
                          "key2" => {"queue_name" => "else_ok", "key" => "key2", "matcher" => {"bus_event_type" => "event_two"}}
                       }
        
      end
    end
  end
end