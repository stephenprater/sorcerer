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
    
    HANDLERS[:brace_block] = HANDLERS[:do_block]
  end
  
  class SimpleMacro < Sorcerer::Source
    def macro_sub(sexp)
      resource(sexp)
    end
    teach_spell :macro_sub

    HANDLERS.merge!({
      [:ident, "macro_expand"] => lambda { |src,sexp|
        src.emit <<-NEWSOURCE
          lambda { puts "I am an expanded macro." (1..5).to_a }.call
        NEWSOURCE
      }
    })
  end
end
      

      

class SorcererPrettySourceTest < Test::Unit::TestCase
  
  def pretty_source(string, debug=false)
    if debug
      puts
      puts ("*" * 80)
    end
    sexp = Ripper::SexpBuilder.new(string).parse
    Sorcerer.pretty_source(sexp)
  end


  def test_available_after_load
    sexp = Ripper::SexpBuilder.new("puts \"foo\"").parse
    assert_raises NoMethodError do
      Sorcerer.pretty_source(sexp)
    end
    require_relative '../../lib/sorcerer/pretty_handlers'
    assert_equal Sorcerer.pretty_source(sexp), "puts \"foo\""
  end

  # the pretty printer is kinda dumb.  it tidies up your
  # code whether you want it to or not.
  def test_pretty_sources_method_with_a_do_block
    source = <<-PRETTY
meth(x, y, *rest, &code) do |a, b=1, c=x, *args, &block|
  one
  two
  three
end
PRETTY
    source.chomp! #pretty doesn't put a newline at end
    assert_pretty_source source
  end

  def test_pretty_sources_prettifies_statment_sequences
    source = "a; b; c"
    result = "a\nb\nc"
    assert_equal pretty_source(source), result
  end

  def test_pretty_source_begin_end
    assert_pretty_source "begin\nend"
    assert_pretty_source "begin\n  a\nend"
    assert_pretty_source "begin\n  a()\nend"
    assert_pretty_source "begin\n  a\n  b\n  c\nend"
  end

  def test_pretty_source_begin_ensure_end
    assert_pretty_source "begin\nensure end"
    assert_pretty_source "begin\nensure b\nend"
    assert_pretty_source "begin\n  a\nensure b\nend"
    assert_pretty_source "begin\n  a\nensure \n  b\nend"
  end

  def test_can_source_begin_rescue_ensure_end
    assert_pretty_source "begin\nrescue\nend"
    assert_pretty_source "begin\nrescue E => ex\n  b\nensure c\nend"
    assert_pretty_source "begin\n  a\nrescue E => ex\n b\nensure c\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\nensure c\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\n  c\nensure d\nend"
    assert_pretty_source "begin\nrescue E, F => ex\n  b\n  c\n  ensure d\nend"
  end

  def test_can_source_begin_rescue_end
    assert_pretty_source "begin\nrescue\nend"
    assert_pretty_source "begin\nrescue E => ex\n   b\nend"
    assert_pretty_source "begin\n  a\nrescue E => ex\n  b\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\n  c\nend"
    assert_pretty_source "begin\nrescue E, F => ex\n  b\n  c\nend"
  end

  private

  def assert_pretty_source string
    assert_equal string, pretty_source(string)
  end
end

    


