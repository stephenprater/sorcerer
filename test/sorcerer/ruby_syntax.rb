## The Ultimate Ruby Syntax Demonstration
#

class A; end

class B < A
end

class C < B
  
  module X
    module_method

    module Y; end
    module Z
      def okay
        self
      end
    end
  end

  class << self
    okay?
    def something
      no
    end
  end

  public
  def method
    whatever
  end

  class C < self
    def huh?
      "right - I don't know"
    end
  end

  protected
  def protected
    whatever
  end


  private
  def private; single_line; end


  def really_public
    ok_then
  end
  public :really_public
  protected :really_public
  #changed my mind
  private :really_public
end
