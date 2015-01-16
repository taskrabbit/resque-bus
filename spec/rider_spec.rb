require 'spec_helper'

module QueueBus
  describe Rider do
    it "should call execute" do
      QueueBus.should_receive(:dispatcher_execute)
      Rider.perform("bus_rider_app_key" => "app", "bus_rider_sub_key" => "sub", "ok" => true, "bus_event_type" => "event_name")
    end

    it "should change the value" do
      QueueBus.dispatch("r1") do
        subscribe "event_name" do |attributes|
          Runner1.run(attributes)
        end
      end
      Runner1.value.should == 0
      Rider.perform("bus_locale" => "en", "bus_timezone" => "PST", "bus_rider_app_key" => "r1", "bus_rider_sub_key" => "event_name", "ok" => true, "bus_event_type" => "event_name")
      Rider.perform("bus_rider_app_key" => "other", "bus_rider_sub_key" => "event_name", "ok" => true, "bus_event_type" => "event_name")
      Runner1.value.should == 1
    end

    it "should set the timezone and locale if present" do
      QueueBus.dispatch("r1") do
        subscribe "event_name" do |attributes|
          Runner1.run(attributes)
        end
      end

      defined?(I18n).should be_nil
      Time.respond_to?(:zone).should eq(false)

      stub_const("I18n", Class.new)
      I18n.should_receive(:locale=).with("en")
      Time.should_receive(:zone=).with("PST")

      Rider.perform("bus_locale" => "en", "bus_timezone" => "PST", "bus_rider_app_key" => "r1", "bus_rider_sub_key" => "event_name", "ok" => true, "bus_event_type" => "event_name")
    end
  end
end
