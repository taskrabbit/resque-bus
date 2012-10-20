require 'spec_helper'

module ResqueBus
  describe SubscriptionList do
    describe ".from_redis" do
      it "should return old attributes" do
        mult = {"event_one" => "myapp_default", "event_two" => "myapp_else_ok"}
        list = SubscriptionList.from_redis(mult)
        list.size.should == 2
        one = list.key("event_one")
        two = list.key("event_two")
        
        one.key.should == "event_one"
        one.event_name.should == "event_one"
        one.queue_name.should == "default"
        
        two.key.should == "event_two"
        two.event_name.should == "event_two"
        two.queue_name.should == "else_ok"
      end
      
      it "should return new attributes" do
        mult = {"event_one" => {"queue_name" => "default", "event_type" => "event_one"}, "event_two" => {"queue_name" => "else", "event_type" => "event_two"}}

        list = SubscriptionList.from_redis(mult)
        list.size.should == 2
        one = list.key("event_one")
        two = list.key("event_two")
        
        one.key.should == "event_one"
        one.event_name.should == "event_one"
        one.queue_name.should == "default"
        
        two.key.should == "event_two"
        two.event_name.should == "event_two"
        two.queue_name.should == "else"
      end
      
      it "should handle a mix" do
        mult = {"event_one" => "myapp_default", "event_two" => {"queue_name" => "else", "event_type" => "event_two"}}

        list = SubscriptionList.from_redis(mult)
        list.size.should == 2
        one = list.key("event_one")
        two = list.key("event_two")

        one.key.should == "event_one"
        one.event_name.should == "event_one"
        one.queue_name.should == "default"

        two.key.should == "event_two"
        two.event_name.should == "event_two"
        two.queue_name.should == "else"
      end
    end
    
    describe "#to_redis" do
      it "should generate what to store" do
        list = SubscriptionList.new
        list.add(Subscription.new("default", "event_one", {}))
        list.add(Subscription.new("else_ok", "event_two", {}))
        
        hash = list.to_redis
        hash.should == {  "event_one" => {"queue_name" => "default", "event_type" => "event_one"}, 
                          "event_two" => {"queue_name" => "else_ok", "event_type" => "event_two"}
                       }
        
      end
    end
  end
end