require 'spec_helper'

module QueueBus
  describe Matcher do
    it "should already return false on empty filters" do
      matcher = Matcher.new({})
      matcher.matches?({}).should  == false
      matcher.matches?(nil).should  == false
      matcher.matches?("name" => "val").should == false
    end

    it "should not crash if nil inputs" do
      matcher = Matcher.new("name" => "val")
      matcher.matches?(nil).should == false
    end

    it "string filter to/from redis" do
      matcher = Matcher.new("name" => "val")
      matcher.matches?("name" => "val").should   == true
      matcher.matches?("name" => " val").should  == false
      matcher.matches?("name" => "zval").should  == false
    end

    it "regex filter" do
      matcher = Matcher.new("name" => /^[cb]a+t/)
      matcher.matches?("name" => "cat").should == true
      matcher.matches?("name" => "bat").should == true
      matcher.matches?("name" => "caaaaat").should == true
      matcher.matches?("name" => "ct").should == false
      matcher.matches?("name" => "bcat").should == false
    end

    it "present filter" do
      matcher = Matcher.new("name" => :present)
      matcher.matches?("name" => "").should == false
      matcher.matches?("name" => "cat").should == true
      matcher.matches?("name" => "bear").should == true
      matcher.matches?("other" => "bear").should == false
    end

    it "blank filter" do
      matcher = Matcher.new("name" => :blank)
      matcher.matches?("name" => nil).should == true
      matcher.matches?("other" => "bear").should == true
      matcher.matches?("name" => "").should == true
      matcher.matches?("name" => "  ").should == true
      matcher.matches?("name" => "bear").should == false
      matcher.matches?("name" => "   s ").should == false
    end

    it "nil filter" do
      matcher = Matcher.new("name" => :nil)
      matcher.matches?("name" => nil).should == true
      matcher.matches?("other" => "bear").should == true
      matcher.matches?("name" => "").should == false
      matcher.matches?("name" => "  ").should == false
      matcher.matches?("name" => "bear").should == false
    end

    it "key filter" do
      matcher = Matcher.new("name" => :key)
      matcher.matches?("name" => nil).should == true
      matcher.matches?("other" => "bear").should == false
      matcher.matches?("name" => "").should == true
      matcher.matches?("name" => "  ").should == true
      matcher.matches?("name" => "bear").should == true
    end

    it "empty filter" do
      matcher = Matcher.new("name" => :empty)
      matcher.matches?("name" => nil).should == false
      matcher.matches?("other" => "bear").should == false
      matcher.matches?("name" => "").should == true
      matcher.matches?("name" => "  ").should == false
      matcher.matches?("name" => "bear").should == false
      matcher.matches?("name" => "   s ").should == false
    end

    it "value filter" do
      matcher = Matcher.new("name" => :value)
      matcher.matches?("name" => nil).should == false
      matcher.matches?("other" => "bear").should == false
      matcher.matches?("name" => "").should == true
      matcher.matches?("name" => "  ").should == true
      matcher.matches?("name" => "bear").should == true
      matcher.matches?("name" => "   s ").should == true
    end

    it "multiple filters" do
      matcher = Matcher.new("name" => /^[cb]a+t/, "state" => "sleeping")
      matcher.matches?("state" => "sleeping", "name" => "cat").should  == true
      matcher.matches?("state" => "awake", "name" => "cat").should     == false
      matcher.matches?("state" => "sleeping", "name" => "bat").should  == true
      matcher.matches?("state" => "sleeping", "name" => "bear").should == false
      matcher.matches?("state" => "awake", "name" => "bear").should    == false
    end

    it "regex should go back and forth into redis" do
      matcher = Matcher.new("name" => /^[cb]a+t/)
      matcher.matches?("name" => "cat").should == true
      matcher.matches?("name" => "bat").should == true
      matcher.matches?("name" => "caaaaat").should == true
      matcher.matches?("name" => "ct").should == false
      matcher.matches?("name" => "bcat").should == false

      QueueBus.redis { |redis| redis.set("temp1", QueueBus::Util.encode(matcher.to_redis) ) }
      redis = QueueBus.redis { |redis| redis.get("temp1") }
      matcher = Matcher.new(QueueBus::Util.decode(redis))
      matcher.matches?("name" => "cat").should == true
      matcher.matches?("name" => "bat").should == true
      matcher.matches?("name" => "caaaaat").should == true
      matcher.matches?("name" => "ct").should == false
      matcher.matches?("name" => "bcat").should == false

      QueueBus.redis { |redis| redis.set("temp2", QueueBus::Util.encode(matcher.to_redis) ) }
      redis = QueueBus.redis { |redis| redis.get("temp2") }
      matcher = Matcher.new(QueueBus::Util.decode(redis))
      matcher.matches?("name" => "cat").should == true
      matcher.matches?("name" => "bat").should == true
      matcher.matches?("name" => "caaaaat").should == true
      matcher.matches?("name" => "ct").should == false
      matcher.matches?("name" => "bcat").should == false
    end

    it "special value should go back and forth into redis" do
      matcher = Matcher.new("name" => :blank)
      matcher.matches?("name" => "cat").should == false
      matcher.matches?("name" => "").should    == true

      QueueBus.redis { |redis| redis.set("temp1", QueueBus::Util.encode(matcher.to_redis) ) }
      redis= QueueBus.redis { |redis| redis.get("temp1") }
      matcher = Matcher.new(QueueBus::Util.decode(redis))
      matcher.matches?("name" => "cat").should == false
      matcher.matches?("name" => "").should    == true

      QueueBus.redis { |redis| redis.set("temp2", QueueBus::Util.encode(matcher.to_redis) ) }
      redis= QueueBus.redis { |redis| redis.get("temp2") }
      matcher = Matcher.new(QueueBus::Util.decode(redis))
      matcher.matches?("name" => "cat").should == false
      matcher.matches?("name" => "").should    == true
    end
  end
end
