require 'test/unit'
require 'ripper'

require_relative '../lib/sorcerer'

require_relative '../lib/pretty_handlers'

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
      

      

class SorcererHandlerTest < Test::Unit::TestCase
  
  def source(string, debug=false)
    if debug
      puts
      puts ("*" * 80)
    end
    sexp = Ripper::SexpBuilder.new(string).parse
  end


