module Sorcerer
  module PrettyHandlers
    include Sorcerer::Handlers
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
      :do_block => lambda { |src, sexp|
        src.emit(" do")
        src.emit_statement_block do
          src.handle_block(sexp)
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
          1
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
          src.emit_statement_block do
            if src.void?(sexp[3])
              src.emit(" ")
            else
              src.emit(" ")
              src.resource(sexp[3])
              src.emit(src.statement_seperator)
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
