require 'test/unit'
require 'ripper'

require_relative '../../lib/sorcerer'

module Sorcerer
  class Transfiguration < Sorcerer::Source
    def transfigure_braces(sexp)
      self.statement_seperator = "\n"
      self.indent = "  "
      resource(sexp)
    end
    teach_spell :transfigure_braces

    def detect_chained_call(sexp)
      source_watch do |exp|
        if source.end_with? "}."
          debugger
          1
        end
      end
      resource(sexp)
    end
    teach_spell :detect_chained_call
   
    handlers do |h|
      h[:brace_block] = h[:do_block]
      h
    end
  end
  
  class SimpleMacro < Sorcerer::Source
    def macro_sub(sexp)
      resource(sexp)
    end
    teach_spell :macro_sub

    handlers do |h|
      h.merge({
        [:ident, "macro_expand"] => lambda { |sexp|
          emit <<-NEWSOURCE
            lambda { puts "I am an expanded macro." (1..5).to_a }.call
          NEWSOURCE
        }
      })
    end
  end
end
      

      

class SorcererPrettySourceTest < Test::Unit::TestCase
  # the pretty source method isn't available before you load the
  # module, but is after you do so
  def test_available_after_load
    sexp = Ripper::SexpBuilder.new("puts \"foo\"").parse
    assert_raises NoMethodError do
      Sorcerer.pretty_source(sexp)
    end
    require_relative '../../lib/sorcerer/pretty_handlers'
    assert_equal Sorcerer.pretty_source(sexp), "puts \"foo\""
  end
end

    


