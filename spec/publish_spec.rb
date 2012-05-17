require 'spec_helper'

describe "Publising an event" do
  it "should add it to Redis" do
    hash = {:one => 1, "two" => "here"}
    event_name = "event_name"
    
    val = ResqueBus.redis.lpop("queue:incoming")
    val.should == nil
    
    ResqueBus.publish(event_name, hash)
    
    val = ResqueBus.redis.lpop("queue:incoming")
    hash = JSON.parse(val)
    hash["event_type"].should == event_name
    hash["class"].should == "ResqueBus::Driver"
    hash["args"].should == {"one" => 1, "two" => "here"}
    
  end
end