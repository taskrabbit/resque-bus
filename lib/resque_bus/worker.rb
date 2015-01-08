module ResqueBus
  class Worker
    # all our workers extend this one

    def perform(*args)
      # instance method level support for sidekiq
      self.class.perform(*args)
    end
  end
end
