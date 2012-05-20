require 'rubygems'
require 'bundler/setup'
require "mocha"
require 'timecop'

require 'resque-bus'

RSpec.configure do |config|
  config.before(:each) do
    ResqueBus.send(:reset)
    ResqueBus.app_key = "test"
  end
  config.after(:each) do
    begin
      ResqueBus.redis.flushall
    rescue
    end
    ResqueBus.send(:reset)
  end
end

ResqueBus.redis.namespace = "resquebus_test"