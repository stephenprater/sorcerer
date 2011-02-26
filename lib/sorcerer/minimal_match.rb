module MinimalMatch
  
  # Array::Anything.  it will always be equal to whatever you compare it to 
  class Anything < BasicObject
    class << self
      def === who_cares
        true
      end
      
      def to_a 
        [AnyNumberOfThings]
      end
    end
  end

  class AnyNumberOfThings < Anything; end

  # a very simple array pattern match for minimal s-exp pjarsing
  # basically, if your array contains at least yourmatch pattern
  # then it will match
  # [a] will match
  # [a b c]
  #
  # [a d] will not
  #
  # that's it.
  #
  def =~ match_array
    # this is a given...
    if self.length < match_array.length
       return false
    end
    
    if match_array.include? AnyNumberOfThings
      match_array = match_array.inject([[]]) do |res,el|
        if el == AnyNumberOfThings
          res << [] 
        else
          res.last << el
        end
        res
      end
      pos = match_array[0].length 
      search_arr = self[0..pos-1]
      return false unless search_arr =~ match_array.shift
      match_array.each do |ma|
        first_match = self[pos..-1].index(ma[0])
        unless first_match
          # special case the last element being AnyNumberOfThings
          return true if match_array.last == []
          first_match = pos
        else
          first_match += pos
        end
        search_arr = self[pos..first_match]
        (search_arr.length - 1).times do
          ma.unshift Anything
        end
        return false unless search_arr =~ ma
        pos = first_match + 1
      end
      return true
    end
       
    match_array.zip(self) do |comp|
      if comp[0].is_a? Array and comp[1].is_a? Array
        return false unless comp[1] =~ comp[0]
      else 
        # comp 0 is our comparison array, comp[1] is us.
        # the case quality operator is not commutative
        # so it's got to be in this order
        unless comp[0] === comp[1]
          return false
        end 
      end
    end
    true
  end
end
