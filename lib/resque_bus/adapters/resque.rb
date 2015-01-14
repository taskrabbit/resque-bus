module ResqueBus
  module Adapters
    class Resque < ResqueBus::Adapters::Base
      def enabled!
        # know we are using it
        require 'resque'

        load_scheduler
        load_retry
      end

      def redis(&block)
        block.call(::Resque.redis)
      end

      def enqueue(queue_name, klass, hash)
        ::Resque.enqueue_to(queue_name, klass, hash)
      end

      def enqueue_at(epoch_seconds, queue_name, klass, hash)
        ::Resque.enqueue_at_with_queue(queue_name, epoch_seconds, klass, hash)
      end

      def setup_heartbeat!(queue_name)
        # turn on the heartbeat
        # should be down after loading scheduler yml if you do that
        # otherwise, anytime
        name     = 'resquebus_hearbeat'
        schedule = { 'class' => '::ResqueBus::Heartbeat',
                     'cron'  => '* * * * *',   # every minute
                     'queue' => queue_name,
                     'description' => 'I publish a heartbeat_minutes event every minute'
                   }
        if ::Resque::Scheduler.dynamic
          ::Resque.set_schedule(name, schedule)
        end
        ::Resque.schedule[name] = schedule
      end

      private

      def load_retry
        require 'resque-retry'
        ::ResqueBus::Rider.extend(::Resque::Plugins::ExponentialBackoff)
        ::ResqueBus::Rider.extend(::ResqueBus::Adapters::Resque::RetryHandlers)
      rescue LoadError
        ::ResqueBus.log_application("resque-retry gem not available: bus retry will not work")
      end

      def load_scheduler
        require 'resque/scheduler'
      rescue LoadError
        ::ResqueBus.log_application("resque-scheduler gem not available: heartbeat and publishing in future will not work")
      end

      module RetryHandlers
        # @failure_hooks_already_ran on https://github.com/defunkt/resque/tree/1-x-stable
        # to prevent running twice
        def queue
          @my_queue
        end

        def on_failure_aaa(exception, *args)
          # note: sorted alphabetically
          # queue needs to be set for rety to work (know what queue in Requeue.class_to_queue)
          @my_queue = args[0]["bus_rider_queue"]
        end

        def on_failure_zzz(exception, *args)
          # note: sorted alphabetically
          @my_queue = nil
        end
      end
    end
  end
end
