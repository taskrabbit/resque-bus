require 'spec_helper'

describe "Publishing an event in the future" do

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
