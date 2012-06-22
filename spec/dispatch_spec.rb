require 'spec_helper' 

module ResqueBus
  describe Dispatch do
    it "should not start with any applications" do
      Dispatch.new.subscriptions.should == {}
    end
    
    it "should register code to run and execute it" do
      dispatch = Dispatch.new
      dispatch.subscribe("my_event") do |attrs|
        Runner1.run(attrs)
      end
      queue, proc = dispatch.subscriptions["my_event"]
      proc.is_a?(Proc).should == true

      Runner.value.should == 0
      dispatch.execute("my_event", {:ok => true})
      Runner1.value.should == 1
      Runner1.attributes.should == {:ok => true}
      
    end
    
    it "should not crash if not there" do
      lambda {
        Dispatch.new.execute("fdkjh", {})
      }.should_not raise_error
    end
    
    describe "Top Level" do
      before(:each) do
        ResqueBus.dispatcher.size.should == 0

         ResqueBus.dispatch do
           subscribe "event1" do |attributes|
             Runner2.run(attributes)
           end

           subscribe "event2" do
             Runner2.run({})
           end

           high "event3" do
             Runner2.run({})
           end
           
           low /^patt.+ern/ do
             Runner.run({})
           end
         end
       end
       
      it "should register and run" do       
        ResqueBus.dispatcher.should_not be_nil
        
        Runner2.value.should == 0
        ResqueBus.dispatcher.execute("event2", {})
        Runner2.value.should == 1
        ResqueBus.dispatcher.execute("event1", {})
        Runner2.value.should == 2
        ResqueBus.dispatcher.execute("event1", {})
        Runner2.value.should == 3
      end
      
      it "should be able to fetch queues" do
        ResqueBus.dispatcher.event_queues.should == { "event1" => "default", "event2" => "default", 
                                                      "event3" => "high", "(?-mix:^patt.+ern)" => "low"}
      end
    
    end
  end

end

