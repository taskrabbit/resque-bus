module ResqueBus
  class Matcher
    SPECIAL_PREPEND = "bus_special_value_"
    attr_reader :filters
    def initialize(hash)
      @filters = encode(hash)
    end
    
    def to_redis
      @filters
    end
    
    def match?(attribute_name, attributes)
      mine = filters[attribute_name].to_s
      return false if mine.size == 0
      
      given = attributes[attribute_name]
      case mine
      when "#{SPECIAL_PREPEND}key"
        return true if attributes.has_key?(attribute_name)
        return false
      when "#{SPECIAL_PREPEND}blank"
        return true if given.to_s.strip.size == 0
        return false
      when "#{SPECIAL_PREPEND}empty"
        return false if given == nil
        return true if given.to_s.size == 0
        return false
      when "#{SPECIAL_PREPEND}nil"
        return true if given == nil
        return false
      when "#{SPECIAL_PREPEND}value"
        return false if given == nil
        return true
      when "#{SPECIAL_PREPEND}present"
        return true if given.to_s.strip.size > 0
        return false
      end
      
      given = given.to_s
      
      return true if mine == given
      begin
        # if it's already a regex, don't mess with it
        # otherwise, it should have start and end line situation
        if mine[0..6] == "(?-mix:"
          regex = Regexp.new(mine)
        else
          regex = Regexp.new("^#{mine}$")
        end
        return !!regex.match(given)
      rescue
        return false
      end
    end
    
    def matches?(attributes)
      return false if filters.empty?
      return false if attributes == nil
      
      filters.keys.each do |key|
        return false unless match?(key, attributes)
      end
      
      true
    end
    
    def encode(hash)
      out = {}
      hash.each do |key, value|
        case value
        when :key, :blank, :nil, :present, :empty, :value
          value = "#{SPECIAL_PREPEND}#{value}"
        end
        out[key.to_s] = value.to_s
      end      
      out
    end
  end
end

