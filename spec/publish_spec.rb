require 'spec_helper'

describe "Publishing an event" do
  
  before(:each) do
    Timecop.freeze
    ResqueBus.stub(:generate_uuid).and_return("idfhlkj")
  end
  after(:each) do
    Timecop.return
  end
  let(:bus_attrs) { {"bus_published_at" => Time.now.to_i,
                     "created_at" => Time.now.to_i,
                     "bus_id"=>"#{Time.now.to_i}-idfhlkj",
                     "bus_app_hostname" =>  `hostname 2>&1`.strip.sub(/.local/,'')} }
  
  it "should add it to Redis" do
    hash = {:one => 1, "two" => "here", "id" => 12 }
    event_name = "event_name"
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    val.should == nil
    
    ResqueBus.publish(event_name, hash)
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    hash = JSON.parse(val)
    hash["class"].should == "ResqueBus::Driver"
    hash["args"].should == [ {"bus_event_type" => event_name, "two"=>"here", "one"=>1, "id" => 12}.merge(bus_attrs) ]
    
  end
  
  it "should use the id if given" do
    hash = {:one => 1, "two" => "here", "bus_id" => "app-given" }
    event_name = "event_name"
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    val.should == nil
    
    ResqueBus.publish(event_name, hash)
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    hash = JSON.parse(val)
    hash["class"].should == "ResqueBus::Driver"
    hash["args"].should == [ {"bus_event_type" => event_name, "two"=>"here", "one"=>1}.merge(bus_attrs).merge("bus_id" => 'app-given') ]
  end
  

  
  it "should set the timezone and locale if available" do
    defined?(I18n).should be_nil
    Time.respond_to?(:zone).should be_false
    
    stub_const("I18n", Class.new)
    I18n.should_receive(:locale).and_return("jp")
    
    Time.should_receive(:zone).and_return(double('zone', :name => "EST"))
    
    hash = {:one => 1, "two" => "here", "bus_id" => "app-given" }
    event_name = "event_name"
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    val.should == nil
    
    ResqueBus.publish(event_name, hash)
    
    val = ResqueBus.redis.lpop("queue:resquebus_incoming")
    hash = JSON.parse(val)
    hash["class"].should == "ResqueBus::Driver"
    att = hash["args"].first
    att["bus_locale"].should == "jp"
    att["bus_timezone"].should == "EST"
  end

end
