module ResqueBus
  module Adapters
    class Resque < ResqueBus::Adapters::Base
      def enabled!
        # know we are using it
        require 'resque'

        # if they have retry, use that
        load_retry
      end

      def redis
        ::Resque.redis
      end

      def enqueue(queue_name, klass, hash)
        push(queue_name, :class => klass.to_s, :args => [hash])
      end

      def enqueue_at(epoch_seconds, queue_name, klass, hash)
        item = delayed_job_to_hash_with_queue(queue_name, klass, [hash])
        delayed_push(epoch_seconds, item)
      end

      def enqueue_to(queue, klass, *args)
        push(queue, :class => klass.to_s, :args => args)
      end


      private

      def load_retry
        require 'resque-retry'
        ::ResqueBus::Rider.extend(::Resque::Plugins::ExponentialBackoff)
        ::ResqueBus::Rider.extend(::ResqueBus::Adapters::Resque::RetryHandlers)
      rescue LoadError
        # nevermind
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





      # TODO: just use resque and resque scheduler directly

      ## From Resque, but using a (possibly) different instance of Redis
      
      # Pushes a job onto a queue. Queue name should be a string and the
      # item should be any JSON-able Ruby object.
      #
      # Resque works generally expect the `item` to be a hash with the following
      # keys:
      #
      #   class - The String name of the job to run.
      #    args - An Array of arguments to pass the job. Usually passed
      #           via `class.to_class.perform(*args)`.
      #
      # Example
      #
      #   Resque.push('archive', :class => 'Archive', :args => [ 35, 'tar' ])
      #
      # Returns nothing
      def push(queue, item)
        watch_queue(queue)
        redis.rpush "queue:#{queue}", ::Resque.encode(item)
      end
      
      # Used internally to keep track of which queues we've created.
      # Don't call this directly.
      def watch_queue(queue)
        redis.sadd(:queues, queue.to_s)
      end
      
      ### From Resque Scheduler
      # Used internally to stuff the item into the schedule sorted list.
      # +timestamp+ can be either in seconds or a datetime object
      # Insertion if O(log(n)).
      # Returns true if it's the first job to be scheduled at that time, else false
      def delayed_push(timestamp, item)
        # First add this item to the list for this timestamp
        redis.rpush("delayed:#{timestamp.to_i}", ::Resque.encode(item))

        # Now, add this timestamp to the zsets.  The score and the value are
        # the same since we'll be querying by timestamp, and we don't have
        # anything else to store.
        redis.zadd :delayed_queue_schedule, timestamp.to_i, timestamp.to_i
      end

      def delayed_job_to_hash_with_queue(queue, klass, args)
        {:class => klass.to_s, :args => args, :queue => queue}
      end
    end
  end
end
