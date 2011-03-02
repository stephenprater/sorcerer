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

  def test_can_pretty_source_method_without_explicit_poetry_mode
    assert_pretty_source "meth a, *args do |x|\n  x.y\nend"
  end

  def test_can_pretty_source_rescue_modifier
    assert_pretty_source "a rescue b"
  end

  def test_pretty_sources_prettifies_statment_sequences
    source = "a; b; c"
    result = "a\nb\nc"
    assert_equal pretty_source(source), result
  end

  def test_can_pretty_source_if
    assert_pretty_source "if a then\n  b\nend"
  end

  def test_can_pretty_source_if_else
    assert_pretty_source "if a then\n  b\nelse\n  c\nend"
  end

  def test_can_pretty_source_if_elsif_else
    assert_pretty_source "if a then\n  b\nelsif c then\n  d\nelse\n  e\nend"
  end

  def test_can_pretty_source_if_elsif
    assert_pretty_source "if a then\n  b\nelsif c then\n  d\nend"
  end

  def test_can_pretty_source_unless
    assert_pretty_source "unless a then\n  b\nend"
  end

  def test_can_pretty_source_unless_else
    assert_pretty_source "unless a then\n  b\nelse\n  c\nend"
  end

  def test_can_pretty_source_while
    assert_pretty_source "while c do\n  body\nend"
  end

  def test_can_pretty_source_until
    assert_pretty_source "until c do\n  body\nend"
  end

  def test_can_pretty_source_for
    assert_pretty_source "for a in list do\nend"
    assert_pretty_source "for a in list do\n  c\nend"
  end

  def test_can_pretty_source_break
    assert_pretty_source "while c do\n  a\n  break if b\n  c\nend"
    assert_pretty_source "while c do\n  a\n  break value if b\n  c\nend"
  end

  def test_can_pretty_source_next
    assert_pretty_source "while c do\n  a\n  next if b\n  c\nend"
  end

  def test_can_pretty_source_case
    assert_pretty_source "case a\n  when b\n    c\nend"
    assert_pretty_source "case a\n  when b\n    c\nwhen d\n    e\nend"
    assert_pretty_source "case a\n  when b\n    c\nwhen d\n    e\nelse\n    f\nend"
  end


  def test_pretty_source_begin_end
    assert_pretty_source "begin\nend"
    assert_pretty_source "begin\n  a\nend"
    assert_pretty_source "begin\n  a()\nend"
    assert_pretty_source "begin\n  a\n  b\n  c\nend"
  end

  def test_pretty_source_begin_ensure_end
    assert_pretty_source "begin\nensure\nend"
    assert_pretty_source "begin\nensure\n  b\nend"
    assert_pretty_source "begin\n  a\nensure\n  b\nend"
  end

  def test_can_source_begin_rescue_ensure_end
    assert_pretty_source "begin\nrescue\nend"
    assert_pretty_source "begin\n  a\nrescue E => ex\n  b\nensure\n  c\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\n  c\nensure\n  d\nend"
    assert_pretty_source "begin\nrescue E, F => ex\n  b\n  c\nensure\n  d\nend"
  end

  def test_can_source_begin_rescue_end
    assert_pretty_source "begin\nrescue\nend"
    assert_pretty_source "begin\nrescue E => ex\n  b\nend"
    assert_pretty_source "begin\n  a\nrescue E => ex\n  b\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\n  c\nend"
    assert_pretty_source "begin\nrescue E, F => ex\n  b\n  c\nend"
  end

  def test_can_source_def
    assert_pretty_source "def f\n  a\nend"
    assert_pretty_source "def f()\nend"
    assert_pretty_source "def f(a)\nend"
    assert_pretty_source "def f(a, b)\nend"
    assert_pretty_source "def f(a, *args)\nend"
    assert_pretty_source "def f(a, *args, &block)\nend"
    assert_pretty_source "def f(a)\n  x\nend"
    assert_pretty_source "def f(a)\n  x\n  y\nend"
  end

  def test_can_source_class_without_parent
    assert_pretty_source "class X\nend"
    assert_pretty_source "class X\n  x\nend"
    assert_pretty_source "class X\n  def f()\n    x\n  end\nend"
  end

  def test_can_source_class_with_parent
    assert_pretty_source "class X < Y\nend"
    assert_pretty_source "class X < Y\n  x\nend"
  end

  def test_can_source_class_with_self_parent
    assert_pretty_source "class X < self\nend"
  end

  def test_can_source_private_etc_in_class
    assert_pretty_source "class X\n  public\n  def f()\n  end\nend"
    assert_pretty_source "class X\n  protected\n  def f()\n  end\nend"
    assert_pretty_source "class X\n  private\n  def f()\n  end\nend"
    assert_pretty_source "class X\n  def f()\n  end\n  public :f\nend"
    assert_pretty_source "class X\n  def f()\n  end\n  protected :f\nend"
    assert_pretty_source "class X\n  def f()\n  end\n  private :f\nend"
  end

  def test_can_source_module
    assert_pretty_source "module X\nend"
    assert_pretty_source "module X\n  x\nend"
    assert_pretty_source "module X\n  def f()\n  end\nend"
  end

  private

  def assert_pretty_source string
    assert_equal string, pretty_source(string)
  end
end

    


