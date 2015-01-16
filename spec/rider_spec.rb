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

    context "Integration Test" do
      before(:each) do
        QueueBus.enqueue_to("testing", "::QueueBus::Rider", { "bus_rider_app_key" => "r2", "bus_rider_sub_key" => "event_name", "bus_event_type" => "event_name", "ok" => true, "bus_rider_queue" => "testing" })

        @worker = Resque::Worker.new(:testing)
        @worker.register_worker
      end

      it "should put it in the failed jobs" do

        QueueBus.dispatch("r2") do
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
