module Sorcerer
  class PrettySource < Sorcerer::Source
    def pretty_source(sexp)
      #barewords are always local
      debugger
      1
    
      self.statement_seperator = "\n"
      self.indent = "  "
      source_watch do |string, exp| 
        if generated_source.end_with? statement_seperator
          generated_source << (indent * indent_level) # that ought to work
        end
      end
      resource(sexp) 
    end
    teach_spell :pretty_source

    def emit_statement_block
      self.indent_level += 1
      emit(statement_seperator)
      yield if block_given?
      self.indent_level -= 1
    end

    handlers do |hs|
      hs.merge({
      # parser keywords
      :BEGIN => lambda { |sexp|
        emit("BEGIN {")
        unless void?(sexp[1])
          emit(" ")
          emit_statement_block do
            resource(sexp[1])
          end
        end
        emit(" }")
      },
     :begin => lambda { |sexp|
        emit("begin")
        emit_statement_block do
          resource(sexp[1])
        end
        emit("end")
      },
      :class => lambda { |sexp|
        resource(sexp[1])
        if ! void?(sexp[2])
          emit " < "
          resource(sexp[2])
        end
        emit_statement_block do
          resource(sexp[3]) unless void?(sexp[3])
        end
        emit("end")
      },
      :def => lambda { |sexp|
        emit("def ")
        resource(sexp[1])
        opt_parens(sexp[2])
        emit_statement_block do
          resource(sexp[3])
        end
        emit("end")
      },
      :if => lambda { |sexp| 
        emit("if ")
        resource(sexp[1])
        emit(" then")
        emit_statement_block do
          resource(sexp[2])
        end
        emit_statement_block do
          resource(sexp[3])
        end
        emit("end")
      },
      :do_block => lambda { |sexp|
        emit(" do")
        # i like block vars on the same line with "do"
        if sexp[1].first == :block_var
          resource(sexp[1])
        end
        emit_statement_block do
          resource(sexp[2])
        end
        emit(statement_seperator)
        emit("end")
      },
      :module => lambda { |sexp|
        emit("module ")
        resource(sexp[1])
        if void?(sexp[2])
          emit(statement_seperator)
        else
          emit_statement_block do
            resource(sexp[2])
          end
        end
        emit("end")
      },
      :rescue => lambda { |sexp|
        emit("rescue")
        if sexp[1]                # Exception list
          emit(" ")
          if sexp[1].first.kind_of?(Symbol)
            resource(sexp[1])
          else
            resource(sexp[1].first)
          end
          emit(" => ")
          resource(sexp[2]) 
        end
        emit(statement_seperator)
        if sexp[3]                # Rescue Code
          unless void?(sexp[3])
            emit_statement_block do
              resource(sexp[3])
            end
          end
        end
      },
      :until => lambda { |sexp|
        emit("until ")
        resource(sexp[1])
        emit(" do ")
        emit_statement_block do 
          resource(sexp[2])
        end
        emit(" end")
      },
     :when => lambda { |sexp|
        emit("when ")
        resource(sexp[1])
        emit(statement_seperator)
        resource(sexp[2])
        if sexp[3] && sexp[3].first == :when
          emit(" ")
        end
        resource(sexp[3])      
      },
      :while => lambda { |sexp|
        emit("while ")
        resource(sexp[1])
        emit(" do ")
        emit_statement_block do
          resource(sexp[2])
        end
        emit(" end")
      }})
    end
  end
end
