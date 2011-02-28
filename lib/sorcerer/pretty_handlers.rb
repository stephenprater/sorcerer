module Sorcerer
  class PrettySource < Sorcerer::Source
    def pretty_source(sexp)
      #barewords are always local
      self.statement_seperator = "\n"
      self.indent = "  "
      source_watch do |string, exp| 
        if generated_source.end_with? statement_seperator and not string == "end"
          generated_source << (indent * indent_level) # that ought to work
        end
      end
      resource(sexp) 
    end
    teach_spell :pretty_source

    def emit_statement_block
      @indent_level += 1
      emit(@statement_seperator)
      yield if block_given?
      @indent_level -= 1
    end


    HANDLERS.merge!({
      # parser keywords
      :BEGIN => lambda { |src, sexp|
        src.emit("BEGIN {")
        unless src.void?(sexp[1])
          src.emit(" ")
          src.emit_statement_block do
            src.resource(sexp[1])
          end
        end
        src.emit(" }")
      },
     :begin => lambda { |src, sexp|
        src.emit("begin")
        src.emit_statement_block do
          src.resource(sexp[1])
        end
        src.emit("end")
      },
      :class => lambda { |src, sexp|
        src.resource(sexp[1])
        if ! src.void?(sexp[2])
          src.emit " < "
          src.resource(sexp[2])
        end
        src.emit_statement_block do
          src.resource(sexp[3]) unless src.void?(sexp[3])
        end
        src.emit("end")
      },
      :def => lambda { |src, sexp|
        src.emit("def ")
        src.resource(sexp[1])
        src.opt_parens(sexp[2])
        src.emit_statement_block do
          src.resource(sexp[3])
        end
        src.emit("end")
      },
      :if => lambda { |src,sexp| 
        src.emit("if ")
        src.resource(sexp[1])
        src.emit(" then")
        src.emit_statement_block do
          src.resource(sexp[2])
        end
        src.emit_statement_block do
          src.resource(sexp[3])
        end
        src.emit("end")
      },
      :do_block => lambda { |src, sexp|
        src.emit(" do")
        # i like block vars on the same line with "do"
        if sexp[1].first == :block_var
          src.resource(sexp[1])
        end
        src.emit_statement_block do
          src.resource(sexp[2])
        end
        src.emit(src.statement_seperator)
        src.emit("end")
      },
      :module => lambda { |src, sexp|
        src.emit("module ")
        src.resource(sexp[1])
        if src.void?(sexp[2])
          src.emit(src.statement_seperator)
        else
          src.emit_statement_block do
            src.resource(sexp[2])
          end
        end
        src.emit("end")
      },
      :rescue => lambda { |src, sexp|
        src.emit("rescue")
        if sexp[1]                # Exception list
          src.emit(" ")
          if sexp[1].first.kind_of?(Symbol)
            src.resource(sexp[1])
          else
            src.resource(sexp[1].first)
          end
          src.emit(" => ")
          src.resource(sexp[2]) 
        end
        src.emit(src.statement_seperator)
        if sexp[3]                # Rescue Code
          unless src.void?(sexp[3])
            src.emit_statement_block do
              src.resource(sexp[3])
            end
          end
        end
      },
      :until => lambda { |src, sexp|
        src.emit("until ")
        src.resource(sexp[1])
        src.emit(" do ")
        src.emit_statement_block do 
          src.resource(sexp[2])
        end
        src.emit(" end")
      },
     :when => lambda { |src, sexp|
        src.emit("when ")
        src.resource(sexp[1])
        src.emit(src.statement_seperator)
        src.resource(sexp[2])
        if sexp[3] && sexp[3].first == :when
          src.emit(" ")
        end
        src.resource(sexp[3])      
      },
      :while => lambda { |src, sexp|
        src.emit("while ")
        src.resource(sexp[1])
        src.emit(" do ")
        src.emit_statement_block do
          src.resource(sexp[2])
        end
        src.emit(" end")
      }
    })
  end
end
