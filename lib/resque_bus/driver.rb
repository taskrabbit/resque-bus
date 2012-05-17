module ResqueBus
  # fans out an event to multiple queues
  class Driver
    
    def self.subscribe(app_name, event_types)
      # need to normalize app name
      
      # if event_types is an array, make a hash wih the default queue #{app_name}_#{default_queue}
      # same if string
      # otherwise if hash, do the sae (prepend app_) to whatever is there (default if nil)
      # if nil or empty event_types, remove the key

      # the goal is to set to key "app:app_name" a json 
      # { "event_name": "app_name_default", "other_event" => "app_name_other_queue"}
      
      # might have to write a set of known app keys or also denormalize to a key like events:event_type (sadd, etc)
    end
    
    def self.queues(event_type)
      # given a string event type, read from redis and return the queues to put it in
      []
    end
    
    def self.perform(event_type, attributes = {})
      raise "No event type passed" if event_type == nil || event_type == ""
      attributes ||= {}
      
      queues(event_type).each do |queue_name|
        enqueue_to(queue_name, Rider, event_type, attributes)
      end
    end
    
    protected
    
    def self.default_queue
      "default"
    end
    
  end
end