require 'resque-bus'
require 'resque/server'
require 'erb'

# Extend Resque::Server to add tabs.
module ResqueBus
  module Server

    def self.included(base)
      base.class_eval {

        get "/bus" do
          erb File.read(File.join(File.dirname(__FILE__), "server/views/bus.erb"))
        end
        
        
        post '/bus/unsubscribe' do
          app = Application.new(params[:name]).unsubscribe
          redirect u('bus')
        end
        
      }
    end
  end
end

Resque::Server.tabs << 'Bus'
Resque::Server.class_eval do
  include ResqueBus::Server
end