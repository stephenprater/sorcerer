require 'test/unit'
require 'ripper'

require_relative '../../lib/sorcerer'
require_relative '../../lib/sorcerer/pretty_handlers'

require_relative '../../lib/sorcerer/minimal_match'
require_relative '../../lib/sorcerer/expression_finder'

module Sorcerer
  class Transfiguration < Sorcerer::PrettySource
    def transfigure_braces(sexp, *args)
      pretty_source(sexp, *args)
    end
    teach_spell :transfigure_braces

    def detect_chained_call(sexp)
      source_watch do |string,sexp|
        debugger
        1
        if resource_obj.current_expression =~ [:brace_block]
          debugger
          1
        end
      end
      transfigure_braces(sexp)
    end
    teach_spell :detect_chained_call
   
    handlers do |h|
      h[:orig_brace_block] = h[:brace_block].dup
      h[:brace_block] = h[:do_block]
      h
    end
  end

  class RegularSource < Sorcerer::Source
    def regular(sexp)
      resource(sexp)
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
      

class SorcererLoadTest < Test::Unit::TestCase
  # the pretty source method isn't available before you load the
  # module, but is after you do so
  def test_not_available_until_spell_taught
    sexp = Ripper::SexpBuilder.new("puts \"foo\"").parse
    assert_raises NoMethodError do
      Sorcerer.regular(sexp)
    end

    Sorcerer::RegularSource.instance_eval do
      teach_spell :regular
    end

    assert_equal Sorcerer.regular(sexp), 'puts "foo"'
  end

  
  def test_transfiguration
    source = <<-SRC 
foo do |m|
  bar
end
SRC
    trans_source = "foo { |m| bar }"
    
    assert_equal(Sorcerer.transfigure_braces(to_sexp(source), :tnl), source )
    assert_equal(Sorcerer.transfigure_braces(to_sexp(trans_source), :tnl), source)
  end

  def test_chained_spells
    source = "foo { |m| bar }.collect { |i| i }.max { |c| c}"
    trans_source = "foo { |m| bar }.collect { |i| i }.max do |c|\n  c\nend"
    debugger
    1

    assert_equal(Sorcerer.detect_chained_call(to_sexp(source)), trans_source)
  end

  private
  def assert_transfigure src, to
    sexp = Ripper::SexpBuilder.new(src).parse
    nsrc = Sorcerer.transfigure_braces(sexp) 
    assert_equal nsrc, to
  end
  
  def to_sexp str
    Ripper::SexpBuilder.new(str).parse
  end

end

    


