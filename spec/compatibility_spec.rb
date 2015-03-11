require 'spec_helper'

describe "migration compatibility" do
  before(:each) do
    ResqueBus.dispatch("r1") do
      subscribe "event_name" do |attributes|
        ResqueBus::Runner1.run(attributes)
      end
    end

    ResqueBus::TaskManager.new(false).subscribe!
    
    @incoming = Resque::Worker.new(:resquebus_incoming)
    @incoming.register_worker

    @new_incoming = Resque::Worker.new(:bus_incoming)
    @new_incoming.register_worker

    @rider = Resque::Worker.new(:r1_default)
    @rider.register_worker
  end
  
  it "should still drive as expected" do
    val = ResqueBus.redis.lpop("queue:bus_incoming")
    val.should == nil
    
    args = [ JSON.generate({"bus_class_proxy"=>"QueueBus::Driver", "bus_event_type" => "event_name", "two"=>"here", "one"=>1, "id" => 12}) ]
    item = {:class => "QueueBus::Worker", :args => args}

    ResqueBus.redis.sadd(:queues, "bus_incoming")
    ResqueBus.redis.rpush "queue:bus_incoming", Resque.encode(item)

    ResqueBus::Runner1.value.should == 0

    perform_next_job @new_incoming

    ResqueBus::Runner1.value.should == 0

    perform_next_job @rider

    ResqueBus::Runner1.value.should == 1
  end
  
  it "should still ride as expected" do
    val = ResqueBus.redis.lpop("queue:r1_default")
    val.should == nil

    args = [ {"bus_rider_app_key"=>"r1", "x" => "y", "bus_event_type" => "event_name", 
              "bus_rider_sub_key"=>"event_name", "bus_rider_queue" => "default", 
              "bus_rider_class_name"=>"::ResqueBus::Rider"}]
    item = {:class => "ResqueBus::Rider", :args => args}
    
    args = [ JSON.generate({"bus_class_proxy"=>"QueueBus::Rider","bus_rider_app_key"=>"r1", "x" => "y", 
                            "bus_event_type" => "event_name", "bus_rider_sub_key"=>"event_name",
                            "bus_rider_queue" => "default"}) ]
    item = {:class => "QueueBus::Worker", :args => args}

    ResqueBus.redis.sadd(:queues, "r1_default")
    ResqueBus.redis.rpush "queue:r1_default", Resque.encode(item)

    ResqueBus::Runner1.value.should == 0

    perform_next_job @rider

    ResqueBus::Runner1.value.should == 1
  end
  
  it "should still publish as expected" do
    val = ResqueBus.redis.lpop("queue:bus_incoming")
    val.should == nil
    
    args = [ JSON.generate({"bus_class_proxy" => "QueueBus::Publisher", "bus_event_type"=>"event_name", "two"=>"here", "one"=>1, "id" => 12}) ]
    item = {:class => "QueueBus::Worker", :args => args}

    ResqueBus.redis.sadd(:queues, "bus_incoming")
    ResqueBus.redis.rpush "queue:bus_incoming", Resque.encode(item)

    ResqueBus::Runner1.value.should == 0

    perform_next_job @new_incoming # publish

    ResqueBus::Runner1.value.should == 0

    perform_next_job @incoming # drive

    ResqueBus::Runner1.value.should == 0

    perform_next_job @rider # ride

    ResqueBus::Runner1.value.should == 1
    
  end
end
