module ResqueBus
  class Matcher
    attr_reader :filters
    def initialize(hash)
      @filters = hash
    end
    
    def to_redis
      @filters
    end
    
    def match?(attribute_name, given)
      mine = filters[attribute_name].to_s
      return false if mine.size == 0
      
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
      raise "no strings!" if attributes.to_s == attributes
      
      # TODO: all filters
      match?("bus_event_type", attributes["bus_event_type"])
    end
  end
end

