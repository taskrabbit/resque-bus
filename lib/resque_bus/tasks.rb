# require 'resquebus/tasks'
# will give you the resquebus tasks

namespace :resquebus do

  desc "Setup will configure a resque task to run before resque:work"
  task :setup => [ :preload ] do
    # Resque.setup # I don't think this does anything? https://github.com/defunkt/resque/blob/master/lib/resque/tasks.rb#L4s
    if ENV['QUEUES'].nil?
      queues = ResqueBus.application.queues
      ENV['QUEUES'] = queues.join(",")
    else
      queues = ENV['QUEUES'].split(",")
    end
    ResqueBus.original_redis = Resque.redis # cache the real resque information if your app uses resque and resque_bus
    Resque.redis = ResqueBus.redis  # switch this worker to go against resque_bus (common) redis
    $resquebus_config = {
      :db => ResqueBus.redis.client.db,
      :host => ResqueBus.redis.client.host,
      :logger => ResqueBus.redis.client.logger,
      :password => ResqueBus.redis.client.password,
      :path => ResqueBus.redis.client.path,
      :port => ResqueBus.redis.client.port,
      :timeout => ResqueBus.redis.client.timeout
    }
    Rake::Task["resquebus:subscribe"].invoke
    if queues.size == 1
      puts "  >>  Working Queue : #{queues.first}"
    else
      puts "  >>  Working Queues: #{queues.join(", ")}"
    end
    Resque.after_fork = Proc.new {
      if ResqueBus
        # puts "reconnecting to Resque Bus' Redis"
        ResqueBus.redis = Redis.new $resquebus_config
      end
    }
  end

  desc "Subscribes this application to ResqueBus events"
  task :subscribe => [ :preload, :setup ] do
    require 'resque-bus'
    event_queues = ResqueBus.dispatcher.event_queues
    raise "No Queues registered" if event_queues.size == 0
    puts "Registering: #{event_queues.inspect}..."
    ResqueBus.application.subscribe(event_queues)
    puts "...done"
  end
  
  desc "Unsubscribes this application from ResqueBus events"
  task :unsubscribe => [ :preload, :setup ] do
    require 'resque-bus'
    puts "Unsubcribing from ResqueBus..."
    ResqueBus.application.unsubscribe
    puts "...done"
  end
  
  desc "Start the ResqueBus driver.  Use: `rake resquebus:driver resque:work`"
  task :driver => [ :preload ] do
    # resquebus_work_queues(["resquebus_incoming"])
    ENV['QUEUES'] = "resquebus_incoming"
    Rake::Task["resquebus:setup"].invoke
  end

  # Preload app files if this is Rails
  task :preload do
    require "resque"
    require "resque-bus"
    
    if defined?(Rails) && Rails.respond_to?(:application)
      # Rails 3
      Rails.application.eager_load!
    elsif defined?(Rails::Initializer)
      # Rails 2.3
      $rails_rake_task = false
      Rails::Initializer.run :load_application_classes
    end
    
    # change the namespace to be the ones used by ResqueBus
    # save the old one for handling later
    ResqueBus.original_redis = Resque.redis
    Resque.redis = ResqueBus.redis
  end
  
  
  # examples to test out the system
  namespace :example do
    desc "Publishes events to example applications"
    task :publish => [ "resquebus:preload", "resquebus:setup" ] do
      which = ["one", "two", "three", "other"][rand(4)]
      ResqueBus.publish("event_#{which}", { "rand" => rand(99999)})
      ResqueBus.publish("event_all", { "rand" => rand(99999)})
      ResqueBus.publish("none_subscribed", { "rand" => rand(99999)})
      puts "published event_#{which}, event_all, none_subscribed"
    end
    
    desc "Sets up an example config"
    task :register => [ "resquebus:preload", "resquebus:setup" ] do
      require 'resque-bus'
      ResqueBus.app_key = "example"
      
      ResqueBus.dispatch do
        subscribe "event_one" do
          puts "event1 happened"
        end

        subscribe "event_two" do
          puts "event2 happened"
        end

        high "event_three" do
          puts "event3 happened (high)"
        end

        low "event_.*" do |attributes|
          puts "LOG ALL: #{attributes.inspect}"
        end
      end
    end
    
    desc "Subscribes this application to ResqueBus example events"
    task :subscribe => [ :register, "resquebus:subscribe" ]
    
    desc "Start a ResqueBus example worker"
    task :work => [ :register, "resquebus:work" ]
    
    desc "Start a ResqueBus example worker"
    task :driver => [ :register, "resquebus:driver" ]
  end
end
