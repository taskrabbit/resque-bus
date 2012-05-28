require 'spec_helper'

describe "Publising an event" do
  
  before(:each) do
    Timecop.freeze
  end
  after(:each) do
    Timecop.return
  end
  let(:the_id) { "idfhlkj" }
  let(:bus_attrs) { {"bus_published_at" => Time.now.to_i, "bus_app_key" => "test", "created_at" => Time.now.to_i, "bus_id"=>"test::#{the_id}"} }
  
  it "should add it to Redis" do
    hash = {:one => 1, "two" => "here", "id" => the_id }
    event_name = "event_name"
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    val.should == nil
    
    ResqueBus.publish(event_name, hash)
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    hash = JSON.parse(val)
    hash["class"].should == "ResqueBus::Driver"
    hash["args"].should == [ "event_name", {"two"=>"here", "one"=>1, "id" => the_id}.merge(bus_attrs) ]
    
  end

end