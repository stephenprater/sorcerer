class SexpSearch
  def initialize sexp
    @sexp = sexp
  end

  def find match 
    @expressions ||= @sexp
    expressions = []
    class_look = lambda do |expression|
      (puts "matched #{expression}"; expressions << expression) if match.is_like? expression
      expression.each do |e| 
        if e.is_a? Array
          class_look.call(e)
        end
      end
    end
    class_look.call(@expressions)
    @expressions = expressions
    self
  end

  def pos
    @expressions
  end

  def pos= old_exp
    @expressions = old_exp
  end

  def rewind
    @expressions = nil 
  end

  def to_a
    @expressions
  end
end
