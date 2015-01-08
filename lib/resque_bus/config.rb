module ResqueBus
  class Config
    def adapter=val
      raise "Adapter already set to #{@adapter_instance.class.name}" if @adapter_instance
      if val.is_a?(Class)
        @adapter_instance = name_or_klass.new
      elsif val.is_a?(ResqueBus::Adapters::Base)
        @adapter_instance = val
      else
        class_name = ResqueBus::Util.classify(val)
        @adapter_instance = ResqueBus::Util.constantize("::ResqueBus::Adapters::#{class_name}").new
      end
      @adapter_instance
    end

    def adapter
      return @adapter_instance if @adapter_instance
      self.adapter = :resque # default
      @adapter_instance
    end

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
