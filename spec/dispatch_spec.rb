require 'spec_helper' 

module ResqueBus
  describe Dispatch do
    it "should not start with any applications" do
      Dispatch.new("d").subscriptions.size.should == 0
    end
    
    it "should register code to run and execute it" do
      dispatch = Dispatch.new("d")
      dispatch.subscribe("my_event") do |attrs|
        Runner1.run(attrs)
      end
      sub = dispatch.subscriptions.key("my_event")
      sub.send(:executor).is_a?(Proc).should == true

      Runner.value.should == 0
      dispatch.execute("my_event", {"bus_event_type" => "my_event", "ok" => true})
      Runner1.value.should == 1
      Runner1.attributes.should == {"bus_event_type" => "my_event", "ok" => true}
      
    end
    
    it "should not crash if not there" do
      lambda {
        Dispatch.new("d").execute("fdkjh", "bus_event_type" => "fdkjh")
      }.should_not raise_error
    end
    
    describe "Top Level" do
      before(:each) do
         ResqueBus.dispatch("testit") do
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
        Runner2.value.should == 0
        ResqueBus.dispatcher_execute("testit", "event2", "bus_event_type" => "event2")
        Runner2.value.should == 1
        ResqueBus.dispatcher_execute("testit", "event1", "bus_event_type" => "event1")
        Runner2.value.should == 2
        ResqueBus.dispatcher_execute("testit", "event1", "bus_event_type" => "event1")
        Runner2.value.should == 3
      end
      
      it "should return the subscriptions" do
        dispatcher = nil
        ResqueBus.dispatchers.each do |d|
          dispatcher = d if d.app_key == "testit"
        end
        subs = dispatcher.subscriptions.all
        tuples = subs.collect{ |sub| [sub.key, sub.queue_name]}
        tuples.should =~ [  ["event1", "testit_default"],
                            ["event2", "testit_default"],
                            ["event3", "testit_high"],
                            [ "(?-mix:^patt.+ern)", "testit_low"]
                         ]
      end
    
    end
  end

end

