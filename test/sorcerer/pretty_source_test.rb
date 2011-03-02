require_relative '../../lib/sorcerer'
require_relative '../../lib/sorcerer/pretty_handlers'
require 'ripper'

class SorcererPrettySourceTest < Test::Unit::TestCase
  
  def pretty_source(string, tn =false)
    sexp = Ripper::SexpBuilder.new(string).parse
    Sorcerer.pretty_source(sexp,tn)
  end

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
    assert_pretty_source "for a in list do end" #void statement in middle
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
    assert_pretty_source "case a\n  when b\n    c\n  when d\n    e\nend"
    assert_pretty_source "case a\n  when b\n    c\n  when d\n    e\n  else\n    f\nend"
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

  def test_can_pretty_source_begin_rescue_ensure_end
    assert_pretty_source "begin\nrescue\nend"
    assert_pretty_source "begin\n  a\nrescue E => ex\n  b\nensure\n  c\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\n  c\nensure\n  d\nend"
    assert_pretty_source "begin\nrescue E, F => ex\n  b\n  c\nensure\n  d\nend"
  end

  def test_can_pretty_source_begin_rescue_end
    assert_pretty_source "begin\nrescue\nend"
    assert_pretty_source "begin\nrescue E => ex\n  b\nend"
    assert_pretty_source "begin\n  a\nrescue E => ex\n  b\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\nend"
    assert_pretty_source "begin\n  a\nrescue E, F => ex\n  b\n  c\nend"
    assert_pretty_source "begin\nrescue E, F => ex\n  b\n  c\nend"
  end

  def test_can_pretty_source_def
    assert_pretty_source "def f\n  a\nend"
    assert_pretty_source "def f(); end"
    assert_pretty_source "def f(a); end"
    assert_pretty_source "def f(a, b); end"
    assert_pretty_source "def f(a, *args); end"
    assert_pretty_source "def f(a, *args, &block); end"
    assert_pretty_source "def f(a)\n  x\nend"
    assert_pretty_source "def f(a)\n  x\n  y\nend"
  end

  def test_can_pretty_source_class_without_parent
    assert_pretty_source "class X; end"
    assert_pretty_source "class X\n  x\nend"
    assert_pretty_source "class X\n\n  def f()\n    x\n  end\nend"
  end

  def test_can_pretty_source_class_with_parent
    assert_pretty_source "class X < Y; end"
    assert_pretty_source "class X < Y\n  x\nend"
  end

  def test_can_pretty_source_class_with_self_parent
    assert_pretty_source "class X < self; end"
  end

  def test_can_pretty_source_meta_class_access
    assert_pretty_source "class << self; end"
    assert_pretty_source "class << self\n  foo\nend"
  end

  def test_can_pretty_source_private_etc_in_class
    assert_pretty_source "class X\n  public\n\n  def f(); end\nend"
    assert_pretty_source "class X\n  protected\n\n  def f(); end\nend"
    assert_pretty_source "class X\n  private\n\n  def f(); end\nend"
    assert_pretty_source "class X\n\n  def f(); end\n  public :f\nend"
    assert_pretty_source "class X\n\n  def f(); end\n  protected :f\nend"
    assert_pretty_source "class X\n\n  def f(); end\n  private :f\nend"
  end

  def test_can_pretty_source_module
    assert_pretty_source "module X; end"
    assert_pretty_source "module X\n  x\nend"
    assert_pretty_source "module X\n\n  def f(); end\nend"
  end

  def test_can_pretty_source_multiple_level_idents
    source = <<-PRETTY
class A

  def c
    d = r
  end

  module A
    G = A::D

    def g
      r
      if r then
        x
      end
      x.each do |okay|
        foo
        bar
      end
    end
  end
end
PRETTY
    assert_pretty_source source, :trailing_newline
  end

  private
  def assert_pretty_source string, tn=false
    assert_equal string, pretty_source(string,tn)
  end
end
