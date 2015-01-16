require 'spec_helper'

module QueueBus
  describe Heartbeat do
    def now_attributes
      {
        "epoch_seconds" => (Time.now.to_i / 60) * 60, # rounded
        "epoch_minutes" => Time.now.to_i / 60,
        "epoch_hours"   => Time.now.to_i / (60*60),
        "epoch_days"    => Time.now.to_i / (60*60*24),
        "minute" => Time.now.min,
        "hour"   => Time.now.hour,
        "day"    => Time.now.day,
        "month"  => Time.now.month,
        "year"   => Time.now.year,
        "yday"   => Time.now.yday,
        "wday"   => Time.now.wday
      }
    end
    
    it "should publish the current time once" do
      Timecop.freeze "12/12/2013 12:01:19" do
        QueueBus.should_receive(:publish).with("heartbeat_minutes", now_attributes)
        Heartbeat.perform
      end
      
      Timecop.freeze "12/12/2013 12:01:40" do
        Heartbeat.perform
      end
    end
    
    it "should publish a minute later" do
      Timecop.freeze "12/12/2013 12:01:19" do
        QueueBus.should_receive(:publish).with("heartbeat_minutes", now_attributes)
        Heartbeat.perform
      end
      
      Timecop.freeze "12/12/2013 12:02:01" do
        QueueBus.should_receive(:publish).with("heartbeat_minutes", now_attributes)
        Heartbeat.perform
      end
    end
  end
end
