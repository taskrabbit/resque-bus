module ResqueBus
  module Util
    def event_matches?(mine, given)
      mine = mine.to_s
      given = given.to_s
      return true if mine == given
      begin
        # if it's already a regex, don't mess with it
        # otherwise, it should ahve start and end line situation
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
  end
end
