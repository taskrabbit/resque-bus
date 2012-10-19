require 'spec_helper'

module ResqueBus
  describe Application do
    describe ".all" do
      it "should return empty array when none" do
        Application.all.should == []
      end
      it "should return registered applications when there are some" do
        Application.new("One").subscribe("fdksjh")
        Application.new("Two").subscribe("fdklhf")
        Application.new("Three").subscribe("fkld")
        
        Application.all.collect(&:app_key).should =~ ["one", "two", "three"]
        
        Application.new("two").unsubscribe
        Application.all.collect(&:app_key).should =~ ["one", "three"]
      end
    end
    
    describe ".new" do
      it "should have a key" do
        Application.new("something").app_key.should == "something"
      
        Application.new("some thing").app_key.should == "some_thing"
        Application.new("some-thing").app_key.should == "some_thing"
        Application.new("some_thing").app_key.should == "some_thing"
        Application.new("Some Thing").app_key.should == "some_thing"
      end
    
      it "should raise an error if not valid" do
        lambda {
          Application.new("")
        }.should raise_error
      
        lambda {
          Application.new(nil)
        }.should raise_error
      
        lambda {
          Application.new("/")
        }.should raise_error
      end
    end
    
  
    describe "#subscribe" do
      it "should add array to redis" do
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
        Application.new("myapp").subscribe(["event_one", "event_two"])
      
        ResqueBus.redis.hgetall("resquebus_app:myapp").should == {"event_one"=>"myapp_default", "event_two"=>"myapp_default"}
        ResqueBus.redis.hkeys("resquebus_app:myapp").should =~ ["event_one", "event_two"]
        ResqueBus.redis.hvals("resquebus_app:myapp").should =~ ["myapp_default", "myapp_default"]
        ResqueBus.redis.smembers("resquebus_apps").should =~ ["myapp"]
      end
      it "should add string to redis" do
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
        Application.new("myapp").subscribe("event_one")
      
        ResqueBus.redis.hgetall("resquebus_app:myapp").should == {"event_one"=>"myapp_default"}
        ResqueBus.redis.hkeys("resquebus_app:myapp").should =~ ["event_one"]
        ResqueBus.redis.hvals("resquebus_app:myapp").should =~ ["myapp_default"]
        ResqueBus.redis.smembers("resquebus_apps").should =~ ["myapp"]
      end
      it "should add hash to redis" do
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
        Application.new("myapp").subscribe({:event_one => :other, :event_two => :default, :event_three => ""})
        ResqueBus.redis.hgetall("resquebus_app:myapp").should == {"event_one"=>"myapp_other", "event_two"=>"myapp_default", "event_three" => "myapp_default"}
        ResqueBus.redis.hkeys("resquebus_app:myapp").should =~ ["event_one", "event_two", "event_three"]
        ResqueBus.redis.hvals("resquebus_app:myapp").should =~ ["myapp_other", "myapp_default", "myapp_default"]
        ResqueBus.redis.smembers("resquebus_apps").should =~ ["myapp"]
      end
    
      it "should do nothing if nil or empty" do
      
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      
        Application.new("myapp").subscribe(nil)
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      
        Application.new("myapp").subscribe("")
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      
        Application.new("myapp").subscribe([])
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      
        Application.new("myapp").subscribe({})
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      end
      it "should call unsubscribe" do
        app = Application.new("myapp")
        app.should_receive(:unsubscribe)
        app.subscribe("")
      end
    end
  
    describe "#unsubscribe" do
      it "should remove items" do
        ResqueBus.redis.sadd("resquebus_apps", "myapp")
        ResqueBus.redis.sadd("resquebus_apps", "other")
        ResqueBus.redis.hset("resquebus_app:myapp", "event_one", "myapp_default")
      
        Application.new("myapp").unsubscribe
      
        ResqueBus.redis.smembers("resquebus_apps").should == ["other"]
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      end
    end
  
    describe "#queues" do
      it "should return one default when none" do
        Application.new("myapp").queues.should =~ ["myapp_default"]
      end
    
      it "should return multiple" do
        Application.new("myapp").subscribe({:event_one => :other, :event_two => :default, :event_three => :default})
        Application.new("myapp").queues.should =~ ["myapp_other", "myapp_default"]
      end
    
       it "should still have the default even when not there" do
          Application.new("myapp").subscribe({:event_one => :other, :event_two => "more here"})
          Application.new("myapp").queues.should =~ ["myapp_other", "myapp_default", "myapp_more_here"]
        end
    end
  
    describe "#event_queues" do
      it "should return empty hash when none" do
        Application.new("myapp").event_queues.should == {}
      end
    
      it "should return them when subscribed" do
        Application.new("myapp").subscribe(["one", "two"])
        Application.new("myapp").event_queues.should == {"one" => "myapp_default", "two" => "myapp_default"}
      end
    end
    
    describe "#events" do
      it "should return empty array when none" do
        Application.new("myapp").events.should == []
      end
    
      it "should return them when subscribed" do
        Application.new("myapp").subscribe(["one", "two"])
        Application.new("myapp").events.should =~ ["one", "two"]
      end
    end
    
    describe "#event_matches" do
      it "should return if it is there" do
        Application.new("myapp").event_matches("three").should == {}
        
        Application.new("myapp").subscribe(["one_x", "one_y", "one", "two"])
        Application.new("myapp").event_matches("three").should == {}
        
        Application.new("myapp").event_matches("two").should == {"two" => "myapp_default"}
        Application.new("myapp").event_matches("one").should == {"one" => "myapp_default"}
      end
      
      it "should handle * wildcards" do
        Application.new("myapp").subscribe(["one.+", "one", "one_.*", "two"])
        Application.new("myapp").event_matches("three").should == {}
        
        Application.new("myapp").event_matches("onex").should == {"one.+" => "myapp_default"}
        Application.new("myapp").event_matches("one").should == {"one" => "myapp_default"}
        Application.new("myapp").event_matches("one_x").should == {"one.+" => "myapp_default", "one_.*" => "myapp_default"}
      end
      
      it "should handle actual regular expressions" do
        Application.new("myapp").subscribe([/one.+/, "one", /one_.*/, "two"])
        Application.new("myapp").event_matches("three").should == {}
        
        Application.new("myapp").event_matches("onex").should == {"(?-mix:one.+)" => "myapp_default"}
        Application.new("myapp").event_matches("donex").should == {"(?-mix:one.+)" => "myapp_default"}
        Application.new("myapp").event_matches("one").should == {"one" => "myapp_default"}
        Application.new("myapp").event_matches("one_x").should == {"(?-mix:one.+)" => "myapp_default", "(?-mix:one_.*)" => "myapp_default"}
      end
    end
    
    describe "#event_matches?" do
      it "should do pattern stuff" do
        app = Application.new("test")
        app.send(:event_matches?, "one", "one").should == true
        app.send(:event_matches?, "one", "onex").should == false
        app.send(:event_matches?, "^one.*$", "onex").should == true
        app.send(:event_matches?, "one.*", "onex").should == true
        app.send(:event_matches?, "one.?", "onex").should == true
        app.send(:event_matches?, "one.?", "one").should == true
        app.send(:event_matches?, "\\", "one").should == false
      end
    end
  end
end