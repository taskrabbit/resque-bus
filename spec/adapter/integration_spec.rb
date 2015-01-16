require 'spec_helper'

describe "Resque Integration" do
  describe "Happy Path" do
    before(:each) do
      QueueBus.dispatch("r1") do
        subscribe "event_name" do |attributes|
          QueueBus::Runner1.run(attributes)
        end
      end

      QueueBus::TaskManager.new(false).subscribe!

      @incoming = Resque::Worker.new(:bus_incoming)
      @incoming.register_worker

      @rider = Resque::Worker.new(:r1_default)
      @rider.register_worker
    end

    it "should publish and receive" do
      QueueBus::Runner1.value.should == 0

      QueueBus.publish("event_name", "ok" => true)
      QueueBus::Runner1.value.should == 0

      perform_next_job @incoming

      QueueBus::Runner1.value.should == 0

      perform_next_job @rider

      QueueBus::Runner1.value.should == 1
    end
  end

  describe "Failed Jobs" do
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

  describe "Delayed Publishing" do
    before(:each) do
      Timecop.freeze(now)
      QueueBus.stub(:generate_uuid).and_return("idfhlkj")
    end
    after(:each) do
      Timecop.return
    end
    let(:delayed_attrs) { {"bus_delayed_until" => future.to_i,
                       "bus_id" => "#{now.to_i}-idfhlkj",
                       "bus_app_hostname" =>  `hostname 2>&1`.strip.sub(/.local/,'')} }

    let(:bus_attrs) { delayed_attrs.merge({"bus_published_at" => worktime.to_i})}
    let(:now)    { Time.parse("01/01/2013 5:00")}
    let(:future) { Time.at(now.to_i + 60) }
    let(:worktime) {Time.at(future.to_i + 1)}

    it "should add it to Redis" do
      hash = {:one => 1, "two" => "here", "id" => 12 }
      event_name = "event_name"
      QueueBus.publish_at(future, event_name, hash)

      schedule = QueueBus.redis { |redis| redis.zrange("delayed_queue_schedule", 0, 1) }
      schedule.should == [future.to_i.to_s]

      val = QueueBus.redis { |redis| redis.lpop("delayed:#{future.to_i}") }
      hash = JSON.parse(val)

      hash["class"].should == "QueueBus::Publisher"
      hash["args"].should == [ {"bus_event_type"=>"event_name", "two"=>"here", "one"=>1, "id" => 12}.merge(delayed_attrs) ]
      hash["queue"].should == "bus_incoming"
    end

    it "should move it to the real queue when processing" do
      hash = {:one => 1, "two" => "here", "id" => 12 }
      event_name = "event_name"

      val = QueueBus.redis { |redis| redis.lpop("queue:bus_incoming") }
      val.should == nil

      QueueBus.publish_at(future, event_name, hash)

      val = QueueBus.redis { |redis| redis.lpop("queue:bus_incoming") }
      val.should == nil # nothing really added

      # process sceduler now
      Resque::Scheduler.handle_delayed_items

      val = QueueBus.redis { |redis| redis.lpop("queue:bus_incoming") }
      val.should == nil # nothing added yet

      # process scheduler in future
      Timecop.freeze(worktime) do
        Resque::Scheduler.handle_delayed_items

        # added
        val = QueueBus.redis { |redis| redis.lpop("queue:bus_incoming") }
        hash = JSON.parse(val)
        hash["class"].should == "QueueBus::Publisher"
        hash["args"].should == [ {"bus_event_type"=>"event_name", "two"=>"here", "one"=>1, "id" => 12}.merge(delayed_attrs) ]

       QueueBus::Publisher.perform(*hash["args"])

       val = QueueBus.redis { |redis| redis.lpop("queue:bus_incoming") }
       hash = JSON.parse(val)
       hash["class"].should == "QueueBus::Driver"
       hash["args"].should == [ {"bus_event_type"=>"event_name", "two"=>"here", "one"=>1, "id" => 12}.merge(bus_attrs) ]
      end
    end

  end
end
