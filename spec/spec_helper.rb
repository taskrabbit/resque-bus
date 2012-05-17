require 'rubygems'
require 'bundler/setup'

require 'resque-bus'

RSpec.configure do |config|
  config.before(:each) do
    ResqueBus.send(:reset)
  end
  config.after(:each) do
    ResqueBus.send(:reset)
  end
end