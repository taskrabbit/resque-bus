# require 'resquebus/tasks'
# will give you the resquebus tasks

namespace :resquebus do

  desc "Setup will configure a resque task to run before resque:work"
  task :setup => [ :preload ] do

    if ENV['QUEUES'].nil?
      manager = ::ResqueBus::TaskManager.new(true)
      queues = manager.queue_names
      ENV['QUEUES'] = queues.join(",")
    else
      queues = ENV['QUEUES'].split(",")
    end

    if queues.size == 1
      puts "  >>  Working Queue : #{queues.first}"
    else
      puts "  >>  Working Queues: #{queues.join(", ")}"
    end
  end

  desc "Provide queue names for setting up a subscribing Sidekiq client"
  task 'setup:sidekiq' => ['preload:sidekiq'] do
    queues = ::ResqueBus::TaskManager.new(true).queue_names
    puts <<OUTPUT
Please configure your subscribing application to use the Sidekiq client with
the following queue#{'s' if queues.count > 1}: #{queues.join(', ')}. For example:

    sidekiq #{ queues.map { |q| "-q #{q} "}.join }

Ultimately you might chain these together in a Procfile:

    rake resquebus:subscribe:sidekiq && sidekiq #{ queues.map { |q| "-q #{q} "}.join }

see https://github.com/mperham/sidekiq/wiki/Advanced-Options#queues for more options.
OUTPUT
  end

  task 'subscribe:base' do
    manager = ::ResqueBus::TaskManager.new(true)
    count = manager.subscribe!
    raise "No subscriptions created" if count == 0
  end

  desc "Subscribes this application to ResqueBus events"
  task :subscribe => [ :preload, 'subscribe:base' ]

  desc "Subscribes this application to ResqueBus events"
  task 'subscribe:sidekiq' => [ 'preload:sidekiq', 'subscribe:base' ]

  desc "Unsubscribes this application from ResqueBus events"
  task :unsubscribe => [ :preload ] do
    require 'resque-bus'
    manager = ::ResqueBus::TaskManager.new(true)
    count = manager.unsubscribe!
    puts "No subscriptions unsubscribed" if count == 0
  end

  desc "Sets the queue to work the driver  Use: `rake resquebus:driver resque:work`"
  task :driver => [ :preload ] do
    ENV['QUEUES'] = "resquebus_incoming"
  end

  desc "Informs the user on how to setup the bus for Sidekiq"
  task "driver:sidekiq" => ['preload:sidekiq'] do
    puts <<OUTPUT
Please configure your driver application to use the Sidekiq client with
the incoming queue: #{ ResqueBus::Publishing::INCOMING_QUEUE }. For example:

    sidekiq -q #{ ResqueBus::Publishing::INCOMING_QUEUE }

Ultimately you might chain these together in a Procfile:

    rake resquebus:driver:sidekiq && sidekiq -q #{ ResqueBus::Publishing::INCOMING_QUEUE }

see https://github.com/mperham/sidekiq/wiki/Advanced-Options#queues for more options.
OUTPUT
  end

  # Preload app files if this is Rails
  task :preload do
    require "resque"
    require "resque-bus"
    require "resque/failure/redis"
    require "resque/failure/multiple_with_retry_suppression"

    ::Resque::Failure::MultipleWithRetrySuppression.classes = [::Resque::Failure::Redis]
    ::Resque::Failure.backend = ::Resque::Failure::MultipleWithRetrySuppression

    Rake::Task["resque:setup"].invoke # loads the environment and such if defined
  end

  task 'preload:sidekiq' do
    require 'resque-bus'
  end

  # examples to test out the system
  namespace :example do
    desc "Publishes events to example applications"
    task :publish => [ "resquebus:preload", "resquebus:setup" ] do
      which = ["one", "two", "three", "other"][rand(4)]
      ::ResqueBus.publish("event_#{which}", { "rand" => rand(99999)})
      ::ResqueBus.publish("event_all", { "rand" => rand(99999)})
      ::ResqueBus.publish("none_subscribed", { "rand" => rand(99999)})
      puts "published event_#{which}, event_all, none_subscribed"
    end

    desc "Sets up an example config"
    task :register => [ "resquebus:preload"] do
      ::ResqueBus.dispatch("example") do
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
