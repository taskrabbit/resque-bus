# require 'resquebus/tasks'
# will give you the resquebus tasks


require "resque/tasks"
namespace :resquebus do

  desc "Setup will configure a resque task to run before resque:work"
  task :setup => [ :preload ] do
    
    if ENV['QUEUES'].nil?
      manager = ::ResqueBus::TaskManager.new(true)
      queues = manager.queue_names.join(",")
      ENV['QUEUES'] = queues.join(",")
    else
      queues = ENV['QUEUES'].split(",")
    end

    if queues.size == 1
      puts "  >>  Working Queue : #{queues.first}"
    else
      puts "  >>  Working Queues: #{queues.join(", ")}"
    end
    
    app_fork = Resque.after_fork
    Resque.after_fork = Proc.new {
      # puts "reconnecting to Resque Bus' Redis"
      ResqueBus.redis.client.reconnect
      app_fork.call if app_fork
    }
  end

  desc "Subscribes this application to ResqueBus events"
  task :subscribe => [ :preload ] do
    manager = ::ResqueBus::TaskManager.new(true)
    count = manager.subscribe!
    raise "No subscriptions created" if count == 0
  end
  
  desc "Unsubscribes this application from ResqueBus events"
  task :unsubscribe => [ :preload ] do
    require 'resque-bus'
    manager = ::ResqueBus::TaskManager.new(true)
    count = manager.unsubscribe!
    puts "No subscriptions unsubscribed" if count == 0
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
    require "resque/failure/redis"

    # change the namespace to be the ones used by ResqueBus
    # save the old one for handling later
    ResqueBus.original_redis = Resque.redis
    Resque.redis = ResqueBus.redis
    
    Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis]
    Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression
    
    Rake::Task["resque:setup"].invoke # loads the environment and such if defined
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
    task :register => [ "resquebus:preload"] do      
      ResqueBus.dispatch("example") do
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
    task :work => [ :register, "resquebus:setup", "resque:work" ]
    
    desc "Start a ResqueBus example worker"
    task :driver => [ :register, "resquebus:driver", "resque:work" ]
  end
end
