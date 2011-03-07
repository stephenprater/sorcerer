module Sorcerer
  class SexpArray < Array
    @@recursion_level = 0
    attr_accessor :parent, :level

    include MinimalMatch

    def initialize arr
      @@recursion_level += 1
      @parent = nil
      super []
      @level = @@recursion_level
      arr.each do |a|
        if a.is_a? Array
          obj = SexpArray.new(a)
          obj.parent = self
          self << obj
        else
          self << a
        end
      end
      self
    end

    def class
      Array
    end

    def next
      # this would be a candidate for memoize
      parent[parent.index(self) + 1]
    end

    def prev
      parent[parent.index(self) - 1]
    end

    def pos
      [@level, parent.index(self)]
    end

    def expressions
      Enumerator.new do |y|
        self.each do |s|
          y << s if s.is_a? SexpArray
        end
      end
    end

    def ancestors 
      Enumerator.new do |y|
        s = self
        while s.parent
          s = s.parent
          y << s
        end
      end
    end
  end
end

