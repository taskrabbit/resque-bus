module ResqueBus
  class TaskManager
    attr_reader :logging
    def initialize(logging)
      @logging = logging
    end
    
    def subscribe!
      count = 0
      ResqueBus.dispatchers.each do |dispatcher|
        subscriptions = dispatcher.subscriptions
        if subscriptions.size > 0
          count += subscriptions.size
          log "Subscribing #{dispatcher.app_key} to #{subscriptions.size} subscriptions"
          app = ResqueBus::Application.new(dispatcher.app_key)
          app.subscribe(subscriptions, logging)
          log "  ...done"
        end
      end
      count
    end
    
    def unsubscribe!
      count = 0
      ResqueBus.dispatchers.each do |dispatcher|
        log "Unsubcribing from #{dispatcher.app_key}"
        app = ResqueBus::Application.new(dispatcher.app_key)
        app.unsubscribe
        count += 1
        log "  ...done"
      end
    end
    
    def queue_names
      # let's not talk to redis in here. Seems to screw things up
      queues = []
      ResqueBus.dispatchers.each do |dispatcher|
        dispatcher.subscriptions.all.each do |sub|
          queues << sub.queue_name
        end
      end
      
      queues.uniq
    end
    
    def log(message)
      puts(message) if logging
    end
  end
end