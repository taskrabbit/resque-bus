require 'spec_helper'

module ResqueBus
  describe Application do
    describe ".all" do
      it "should return empty array when none" do
        Application.all.should == []
      end
      it "should return registered applications when there are some" do
        Application.new("One").subscribe(test_list(test_sub("fdksjh")))
        Application.new("Two").subscribe(test_list(test_sub("fdklhf")))
        Application.new("Three").subscribe(test_list(test_sub("fkld")))
        
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
    
    describe "#no_connect_queue_names_for" do      
      it "should generate names" do
        app = Application.new("myapp")
        list = test_list(test_sub("event_one", "default"), test_sub("event_two", "default"), test_sub("event_three", "other"))
        app.no_connect_queue_names_for(list).should =~ ["myapp_other", "myapp_default"]       
      end
    end
    
    describe "#read_redis_hash" do
      it "should handle old and new values" do
        
        ResqueBus.redis.hset("resquebus_app:myapp", "new_one", Resque.encode("queue_name" => "x", "event_type" => "event_name"))
        ResqueBus.redis.hset("resquebus_app:myapp", "old_one", "oldqueue_name")
        app = Application.new("myapp")
        val = app.send(:read_redis_hash)
        val.should == {"new_one" => {"queue_name" => "x", "event_type" => "event_name"}, "old_one" => "oldqueue_name"}
      end
    end
  
    describe "#subscribe" do
      let(:sub1) { test_sub("event_one", "default") }
      let(:sub2) { test_sub("event_two", "default") }
      let(:sub3) { test_sub("event_three", "other") }
      it "should add array to redis" do
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
        Application.new("myapp").subscribe(test_list(sub1, sub2))
      
        ResqueBus.redis.hgetall("resquebus_app:myapp").should == {
                                            "event_two"=>"{\"queue_name\":\"default\",\"key\":\"event_two\",\"matcher\":{\"bus_event_type\":\"event_two\"}}", 
                                            "event_one"=>"{\"queue_name\":\"default\",\"key\":\"event_one\",\"matcher\":{\"bus_event_type\":\"event_one\"}}"}
        ResqueBus.redis.hkeys("resquebus_app:myapp").should =~ ["event_one", "event_two"]
        ResqueBus.redis.smembers("resquebus_apps").should =~ ["myapp"]
      end
      it "should add string to redis" do
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
        Application.new("myapp").subscribe(test_list(sub1))
      
        ResqueBus.redis.hgetall("resquebus_app:myapp").should == {"event_one"=>"{\"queue_name\":\"default\",\"key\":\"event_one\",\"matcher\":{\"bus_event_type\":\"event_one\"}}"}
        ResqueBus.redis.hkeys("resquebus_app:myapp").should =~ ["event_one"]
        ResqueBus.redis.smembers("resquebus_apps").should =~ ["myapp"]
      end
      it "should multiple queues to redis" do
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
        Application.new("myapp").subscribe(test_list(sub1, sub2, sub3))
        ResqueBus.redis.hgetall("resquebus_app:myapp").should == {
                                            "event_two"=>"{\"queue_name\":\"default\",\"key\":\"event_two\",\"matcher\":{\"bus_event_type\":\"event_two\"}}", "event_one"=>"{\"queue_name\":\"default\",\"key\":\"event_one\",\"matcher\":{\"bus_event_type\":\"event_one\"}}",
                                            "event_three"=>"{\"queue_name\":\"other\",\"key\":\"event_three\",\"matcher\":{\"bus_event_type\":\"event_three\"}}"}
        ResqueBus.redis.hkeys("resquebus_app:myapp").should =~ ["event_three", "event_two", "event_one"]
        ResqueBus.redis.smembers("resquebus_apps").should =~ ["myapp"]
      end
    
      it "should do nothing if nil or empty" do
      
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      
        Application.new("myapp").subscribe(nil)
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      
        Application.new("myapp").subscribe([])
        ResqueBus.redis.get("resquebus_app:myapp").should be_nil
      end
      
      it "should call unsubscribe" do
        app = Application.new("myapp")
        app.should_receive(:unsubscribe)
        app.subscribe([])
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
    
    describe "#subscription_tuples" do
      it "should return if it is there" do
        Application.new("myapp").subscription_tuples("bus_event_type"=>"three").should == []
        
        subs = test_list(test_sub("one_x"), test_sub("one_y"), test_sub("one"), test_sub("two"))
        Application.new("myapp").subscribe(subs)
        Application.new("myapp").subscription_tuples("bus_event_type"=>"three").should == []
        
        Application.new("myapp").subscription_tuples("bus_event_type"=>"two").should =~ [["two", "myapp_default"]]
        Application.new("myapp").subscription_tuples("bus_event_type"=>"one").should =~ [["one", "myapp_default"]]
      end
      
      it "should handle * wildcards" do
        subs = test_list(test_sub("one.+"), test_sub("one"), test_sub("one_.*"), test_sub("two"))
        Application.new("myapp").subscribe(subs)
        Application.new("myapp").subscription_tuples("bus_event_type"=>"three").should == []
        
        Application.new("myapp").subscription_tuples("bus_event_type"=>"onex").should =~ [["one.+", "myapp_default"]]
        Application.new("myapp").subscription_tuples("bus_event_type"=>"one").should =~ [["one", "myapp_default"]]
        Application.new("myapp").subscription_tuples("bus_event_type"=>"one_x").should =~ [["one.+","myapp_default"], ["one_.*", "myapp_default"]]
      end
      
      it "should handle actual regular expressions" do
        subs = test_list(test_sub(/one.+/), test_sub("one"), test_sub(/one_.*/), test_sub("two"))
        Application.new("myapp").subscribe(subs)
        Application.new("myapp").subscription_tuples("bus_event_type"=>"three").should == []
        
        Application.new("myapp").subscription_tuples("bus_event_type"=>"onex").should =~ [["(?-mix:one.+)", "myapp_default"]]
        Application.new("myapp").subscription_tuples("bus_event_type"=>"donex").should =~ [["(?-mix:one.+)", "myapp_default"]]
        Application.new("myapp").subscription_tuples("bus_event_type"=>"one").should =~ [["one" ,"myapp_default"]]
        Application.new("myapp").subscription_tuples("bus_event_type"=>"one_x").should =~ [["(?-mix:one.+)", "myapp_default"], ["(?-mix:one_.*)", "myapp_default"]]
      end
    end
  end
end