module ResqueBus
  class Config
    def default_app_key=val
      @default_app_key = Application.normalize(val)
    end
    
    def default_app_key
      @default_app_key
    end
    
    def default_queue=val
      @default_queue = val
    end
    
    def default_queue
      @default_queue
    end

    def local_mode=value
      @local_mode = value
    end

    def local_mode
      @local_mode
    end

    def hostname
      @hostname ||= `hostname 2>&1`.strip.sub(/.local/,'')
    end

    def hostname=val
      @hostname = val
    end

    def before_publish=(proc)
      @before_publish_callback = proc
    end

    def before_publish_callback(attributes)
      if @before_publish_callback
        @before_publish_callback.call(attributes)
      end
    end

    def logger
      @logger
    end
    
    def logger=val
      @logger = val
    end
    
    def log_application(message)
      if logger
        time = Time.now.strftime('%H:%M:%S %Y-%m-%d')
        logger.info("** [#{time}] #$$: ResqueBus #{message}")
      end
    end
    
    def log_worker(message)
      if ENV['LOGGING'] || ENV['VERBOSE'] || ENV['VVERBOSE']
        time = Time.now.strftime('%H:%M:%S %Y-%m-%d')
        puts "** [#{time}] #$$: #{message}"
      end
    end
  end
end
