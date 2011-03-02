module Sorcerer
  class PrettySource < Sorcerer::Source
    # a list of words which appear at the same
    # indent level as their "begin" word.
    
    def pretty_source(sexp)
      #barewords are always local
      self.statement_seperator = "\n"
      self.indent = "  "
      source_watch do |string, exp|
        if generated_source.end_with? statement_seperator
          next if string.length == 0
          generated_source << (indent * indent_level) # that ought to work
        end
      end
      resource(sexp) 
    end
    teach_spell :pretty_source

    def emit_statement_block 
      emit(statement_seperator)
      self.indent_level += 1 
      yield if block_given?
      self.indent_level -= 1 
      emit(statement_seperator)
    end

    def emit string, supress_indent=false
      self.indent_level -= 1 if supress_indent 
      super string
      self.indent_level += 1 if supress_indent
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
      :bodystmt => lambda { |sexp|
        resource(sexp[1])     # Main Body
        emit(statement_seperator)
        resource(sexp[2])   # Rescue
        resource(sexp[4])   # Ensure
      },
      :body_stmt => hs[:bodystmt],
      :class => lambda { |sexp|
        emit("class ")
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
      :unless => lambda { |sexp|
        emit("unless ")
        resource(sexp[1])
        emit(" then")
        emit_statement_block do
          resource(sexp[2])
        end
        resource(sexp[3])
        emit("end")
      },
      :if => lambda { |sexp| 
        emit("if ")
        resource(sexp[1])
        emit(" then")
        emit_statement_block do
          resource(sexp[2])
        end
        resource(sexp[3])
        emit("end")
      },
      :else => lambda { |sexp|
        emit("else")
        emit_statement_block do
          resource(sexp[1])
        end
      },
      :elsif => lambda { |sexp|
        emit("elsif ")
        resource(sexp[1])
        emit(" then")
        emit_statement_block do
          resource(sexp[2])
        end
        resource(sexp[3])
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
        emit("rescue",:no_indent)
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
        if sexp[3]                # Rescue Code
          unless void?(sexp[3])
            resource(sexp[3])
          end
        end
      },
      :ensure => lambda { |sexp|
        emit("ensure",:no_indent)
        if sexp[1]
          unless void?(sexp[1]) 
            resource(sexp[1])
          end
        end
      },
      :until => lambda { |sexp|
        emit("until ")
        resource(sexp[1])
        emit(" do")
        emit_statement_block do 
          resource(sexp[2])
        end
        emit("end")
      },
      :case => lambda { |sexp|
        emit("case ")
        resource(sexp[1]) # variable
        emit_statement_block do 
          resource(sexp[2])
        end
        emit("end")
      },
     :when => lambda { |sexp|
        emit("when ")
        resource(sexp[1])
        emit_statement_block do
          resource(sexp[2])
        end
        if sexp[3] && sexp[3].first == :when
          emit(" ")
        end
        emit_statement_block do
          resource(sexp[3])      
        end
      },
      :while => lambda { |sexp|
        emit("while ")
        resource(sexp[1])
        emit(" do")
        emit_statement_block do
          resource(sexp[2])
        end
        emit("end")
      }})
    end
  end
end
