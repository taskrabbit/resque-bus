module ResqueBus
  module Heartbeating
    def heartbeat!
      # turn on the heartbeat
      # should be down after loading scheduler yml if you do that
      # otherwise, anytime
      require 'resque/scheduler'
      name     = 'resquebus_hearbeat'
      schedule = { 'class' => '::ResqueBus::Heartbeat',
                   'cron'  => '* * * * *',   # every minute
                   'queue' => incoming_queue,
                   'description' => 'I publish a heartbeat_minutes event every minute'
                 }
      if Resque::Scheduler.dynamic
        Resque.set_schedule(name, schedule)
      end
      Resque.schedule[name] = schedule
    end
  end
end
