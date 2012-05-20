require 'spec_helper'

module ResqueBus
  describe Driver do
    describe "#queue_matches" do
      before(:each) do
        ResqueBus.subscribe("app1", ["event1", "event2", "event3"])
        ResqueBus.subscribe("app2", {"event2" => "other", "event4" => "more"})
        ResqueBus.subscribe("app3", ["event[45]", "event5", "event6"])
      end
      it "return empty array when none" do
        Driver.queue_matches("else").should == []
        Driver.queue_matches("event").should == []
      end
      it "should return a match" do
        Driver.queue_matches("event1").should =~ [["event1", "app1_default"]]
        Driver.queue_matches("event6").should =~ [["event6", "app3_default"]]
      end
      it "should match multiple apps" do
        Driver.queue_matches("event2").should =~ [["event2", "app1_default"], ["event2", "app2_other"]]
      end
      it "should match multiple apps with patterns" do
        Driver.queue_matches("event4").should =~ [["event[45]", "app3_default"], ["event4", "app2_more"]]
      end
      it "should match multiple events in same app" do
        Driver.queue_matches("event5").should =~ [["event[45]", "app3_default"], ["event5", "app3_default"]]
      end
    end
  end
end