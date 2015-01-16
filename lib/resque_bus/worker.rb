module ResqueBus
  class Worker
    # all our workers extend this one
    module InstanceMethods
      def perform(*args)
        # instance method level support for sidekiq
        self.class.perform(*args)
      end
    end
    include InstanceMethods
  end
end
