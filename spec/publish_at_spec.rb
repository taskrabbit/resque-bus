require 'spec_helper'

describe "Publishing an event in the future" do
  
  before(:each) do
    Timecop.freeze(now)
    ResqueBus.stub(:generate_uuid).and_return("idfhlkj")
  end
  after(:each) do
    Timecop.return
  end
  let(:delayed_attrs) { {"bus_delayed_until" => future.to_i,
                     "bus_id" => "#{now.to_i}-idfhlkj",
                     "bus_app_hostname" =>  `hostname 2>&1`.strip.sub(/.local/,'')} }
  
  let(:bus_attrs) { delayed_attrs.merge({"bus_published_at" => worktime.to_i})}
  let(:now)    { Time.parse("01/01/2013 5:00")}                   
  let(:future) { Time.at(now.to_i + 60) }
  let(:worktime) {Time.at(future.to_i + 1)}
  
  it "should add it to Redis" do
    hash = {:one => 1, "two" => "here", "id" => 12 }
    event_name = "event_name"
    ResqueBus.publish_at(future, event_name, hash)
    
    schedule = ResqueBus.redis.zrange("delayed_queue_schedule", 0, 1)
    schedule.should == [future.to_i.to_s]
    
    val = ResqueBus.redis.lpop("delayed:#{future.to_i}")
    hash = JSON.parse(val)

    hash["class"].should == "ResqueBus::Publisher"
    hash["args"].should == [ {"bus_event_type"=>"event_name", "two"=>"here", "one"=>1, "id" => 12}.merge(delayed_attrs) ]
    hash["queue"].should == "resquebus_incoming"
  end

  it "should move it to the real queue when processing" do
    hash = {:one => 1, "two" => "here", "id" => 12 }
    event_name = "event_name"
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    val.should == nil
    
    ResqueBus.publish_at(future, event_name, hash)
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    val.should == nil # nothing really added
    
    # process sceduler now
    Resque::Scheduler.handle_delayed_items
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    val.should == nil # nothing added yet
    
    # process scheduler in future
    Timecop.freeze(worktime) do
      Resque::Scheduler.handle_delayed_items
      
      # added
      val = ResqueBus.redis.lpop("queue:resquebus_incoming")
      hash = JSON.parse(val)
      hash["class"].should == "ResqueBus::Publisher"
      hash["args"].should == [ {"bus_event_type"=>"event_name", "two"=>"here", "one"=>1, "id" => 12}.merge(delayed_attrs) ]
      
     ResqueBus::Publisher.perform(*hash["args"])
     
     val = ResqueBus.redis.lpop("queue:resquebus_incoming")
     hash = JSON.parse(val)
     hash["class"].should == "ResqueBus::Driver"
     hash["args"].should == [ {"bus_event_type"=>"event_name", "two"=>"here", "one"=>1, "id" => 12}.merge(bus_attrs) ]
    end
  end

end
