module ResqueBus
  module Adapters
    class Base
      # adapters need to define the NonImplemented methods in this class
      
      def initialize
        enabled!
      end

      def enabled!
        # called the first time we know we are using this adapter
        # it would be a good spot to require the libraries you're using
        raise NotImplementedError
      end

      def redis
        # for now, we're always using redis as a storage mechanism so give us one
        raise NotImplementedError
      end

      def enqueue(queue_name, klass, hash)
        # enqueue the given class (Driver) in your queue
        raise NotImplementedError
      end

      def enqueue_at(epoch_seconds, queue_name, klass, hash)
        # enqueue the given class (Publisher) in your queue to run at given time
        raise NotImplementedError
      end
    end
  end
end
