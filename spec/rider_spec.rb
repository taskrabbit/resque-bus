require 'spec_helper'

module ResqueBus
  describe Rider do
    it "should call execute" do
      ResqueBus.dispatcher.should_receive(:execute)
      Rider.perform("ok" => true, "bus_event_type" => "event_name")
    end
    
    it "should change the value" do
      ResqueBus.dispatcher.size.should == 0

      ResqueBus.dispatch do
        subscribe "event_name" do |attributes|
          Runner1.run(attributes)
        end
      end
      Runner1.value.should == 0
      Rider.perform("event_name", {"ok" => true, "bus_event_type" => "event_name"})
      Runner1.value.should == 1
    end
    
    
    context "Integration Test" do
      before(:each) do
        Resque.redis = "example.com/bad"
        ResqueBus.original_redis =  Resque.redis
        ResqueBus.redis = "localhost:6379"
        
        
        ResqueBus.enqueue_to("testing", Rider, "event_name", 
                { "bus_event_type" => "event_name", "ok" => true, "bus_rider_queue" => "testing" })
        
        # like the job does
        Resque.redis = ResqueBus.redis
        
        @worker = Resque::Worker.new(:testing)
        @worker.register_worker
      end
      
      it "should use the app's redis within the rider" do
        host = Resque.redis.instance_variable_get("@redis").instance_variable_get("@client").host
        host.should == "localhost"
        
        ResqueBus.dispatch do
          subscribe "event_name" do |attributes|
            host = Resque.redis.instance_variable_get("@redis").instance_variable_get("@client").host
            if host == "example.com"
              Runner1.run(attributes)
            end
          end
        end
        
        host = Resque.redis.instance_variable_get("@redis").instance_variable_get("@client").host
        host.should == "localhost"
        
        
        Runner1.value.should == 0
        perform_next_job @worker
        Runner1.value.should == 1
      end
      
      it "should put it in the failed jobs" do
 
        ResqueBus.dispatch do
          subscribe "event_name" do |attributes|
            raise "boo!"
          end
        end
        
        perform_next_job @worker
        Resque.info[:processed].should == 1
        Resque.info[:failed].should == 1
        Resque.info[:pending].should == 1 # requeued

        perform_next_job @worker
        Resque.info[:processed].should == 2
        Resque.info[:failed].should == 2
        Resque.info[:pending].should == 0
      end
    end
   
    
  end
end