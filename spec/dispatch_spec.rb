require 'spec_helper' 

module ResqueBus
  class Runner
    def self.value
      @value ||= 0
    end
    
    def self.attributes
      @attributes
    end
    
    def self.run(attrs)
      @value ||= 0
      @value += 1
      @attributes = attrs
    end
  end
  
  class Runner1 < Runner
  end
  
  class Runner2 < Runner
  end
  
  describe Dispatch do
    it "should not start with any applications" do
      Dispatch.new.subscriptions.should == {}
    end
    
    it "should register code to run and execute it" do
      dispatch = Dispatch.new
      dispatch.subscribe("my_event") do |attrs|
        Runner1.run(attrs)
      end
      dispatch.subscriptions["my_event"].is_a?(Proc).should == true

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
      it "should register" do
        ResqueBus.dispatcher.should be_nil
        
        ResqueBus.dispatch do
          subscribe "event1" do |attributes|
            Runner2.run(attributes)
          end
          
          subscribe "event2" do
            Runner2.run({})
          end
        end
        
        ResqueBus.dispatcher.should_not be_nil
        
        Runner2.value.should == 0
        ResqueBus.dispatcher.execute("event2", {})
        Runner2.value.should == 1
        ResqueBus.dispatcher.execute("event1", {})
        Runner2.value.should == 2
        ResqueBus.dispatcher.execute("event1", {})
        Runner2.value.should == 3
      end
    end
  end

end

