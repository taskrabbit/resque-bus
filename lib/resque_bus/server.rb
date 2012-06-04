require 'resque/server'

# patch Resque::Server to have an additional tab
module Resque
  class Server < Sinatra::Base
    def self.tabs
      @tabs ||= ["Overview", "Working", "Failed", "Queues", "Workers", "Stats", "Bus"]
    end
    
    def self.bus_views
      @bus_views ||= "#{File.dirname(File.expand_path(__FILE__))}/server/views"
    end
    
    def bus_show(page, layout = true)
      response["Cache-Control"] = "max-age=0, private, must-revalidate"
      begin
        output = erb(page.to_sym, {:layout => false, :views => self.class.bus_views}, :resque => Resque)
        if layout
          return render(:erb, @default_layout, {:layout => false}, {}) { output }
        else
          return output
        end
      rescue Errno::ECONNREFUSED
        erb :error, {:layout => false}, :error => "Can't connect to Redis! (#{Resque.redis_id})"
      end
    end
    
    get "/bus/?" do
      bus_show :bus
    end
  end
end