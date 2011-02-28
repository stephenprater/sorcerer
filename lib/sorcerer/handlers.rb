require 'ruby-debug'

module Sorcerer
  class Source < HandlerClass  
    def source(sexp)
      resource(sexp)
    end
    teach_spell :source

    def handle_block(sexp)
      resource(sexp[1])     # Arguments
      if ! void?(sexp[2])
        emit(" ")
        resource(sexp[2])     # Statements
      end
      emit(" ")
    end
    
    def words(marker, sexp)
      emit("%#{marker}{") if @word_level == 0
      @word_level += 1
      if sexp[1] != [:qwords_new] && sexp[1] != [:words_new]
        resource(sexp[1])
        emit(" ")
      end
      resource(sexp[2])
      @word_level -= 1
      emit("}") if @word_level == 0
    end

    def opt_parens(sexp)
      emit(" ") unless sexp.first == :arg_paren || sexp.first == :paren
      resource(sexp)
    end

    def emit_separator(sep, first)
      emit(sep) unless first
      false
    end

    def params(normal_args, default_args, rest_args, unknown, block_arg)
      first = true
      if normal_args
        normal_args.each do |sx|
          first = emit_separator(", ", first)
          resource(sx)
        end
      end
      if default_args
        default_args.each do |sx|
          first = emit_separator(", ", first)
          resource(sx[0])
          emit("=")
          resource(sx[1])
        end
      end
      if rest_args
        first = emit_separator(", ", first)
        resource(rest_args)
      end
      if block_arg
        first = emit_separator(", ", first)
        resource(block_arg)
      end
    end


    HANDLERS = {
      # parser keywords
      :BEGIN => lambda { |sexp|
        emit("BEGIN {")
        unless void?(sexp[1])
          emit(" ")
          resource(sexp[1])
        end
        emit(" }")
      },
      :END => lambda { |sexp|
        emit("END {")
        unless void?(sexp[1])
          emit(" ")
          resource(sexp[1])
        end
        emit(" }")
      },
      :alias => lambda { |sexp|
        emit("alias ")
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
      },
      :alias_error => NYI,
      :aref => lambda { |sexp|
        resource(sexp[1])
        emit("[")
        resource(sexp[2])
        emit("]")
      },
      :aref_field => lambda { |sexp|
        resource(sexp[1])
        emit("[")
        resource(sexp[2])
        emit("]")
      },
      :arg_ambiguous => NYI,
      :arg_paren => lambda { |sexp|
        emit("(")
        resource(sexp[1]) if sexp[1]
        emit(")")
      },
      :args_add => lambda { |sexp|
        resource(sexp[1])
        if sexp[1].first != :args_new
          emit(", ")
        end
        resource(sexp[2])
      },
      :args_add_block => lambda { |sexp|
        resource(sexp[1])
        if sexp[2]
          if sexp[1].first != :args_new
            emit(", ")
          end
          if sexp[2]
            emit("&")
            resource(sexp[2])
          end
        end
      },
      :args_add_star => lambda { |sexp|
        resource(sexp[1])
        if sexp[1].first != :args_new
          emit(", ")
        end
        emit("*")
        resource(sexp[2])
      },
      :args_new => NOOP,
      :args_prepend => NYI,
      :array => lambda { |sexp|
        emit("[")
        resource(sexp[1])
        emit("]")
      },
      :assign => lambda { |sexp|
        resource(sexp[1])
        emit(" = ")
        resource(sexp[2])
      },
      :assign_error => NYI,
      :assoc_new => lambda { |sexp|
        resource(sexp[1])
        emit(" => ")
        resource(sexp[2])
      },
      :assoclist_from_args => lambda { |sexp|
        first = true
        sexp[1].each do |sx|
          emit(", ") unless first
          first = false
          resource(sx)
        end
      },
      :bare_assoc_hash => lambda { |sexp|
        first = true
        sexp[1].each do |sx|      
          emit(", ") unless first
          first = false
          resource(sx)
        end
      },
      :begin => lambda { |sexp|
        emit("begin")
        resource(sexp[1])
        emit("end")
      },
      :binary => lambda { |sexp|
        resource(sexp[1])
        emit(" #{sexp[2]} ")
        resource(sexp[3])
      },
      :block_var => lambda { |sexp|
        emit(" |")
        resource(sexp[1])
        emit("|")
      },
      :block_var_add_block => NYI,
      :block_var_add_star => NYI,
      :blockarg => lambda { |sexp|
        emit("&")
        resource(sexp[1])
      },
      :body_stmt => lambda { |sexp|
        resource(sexp[1])     # Main Body
        emit(statement_seperator)
        resource(sexp[2])   # Rescue
        resource(sexp[4])   # Ensure
      },
      :brace_block => lambda { |sexp|
        emit(" {")
        handle_block(sexp)
        emit("}")
      },
      :break => lambda { |sexp|
        emit("break")
        emit(" ") unless sexp[1] == [:args_new]
        resource(sexp[1])
      },
      :call => lambda { |sexp|
        resource(sexp[1])
        emit(sexp[2])
        resource(sexp[3]) unless sexp[3] == :call
      },
      :case => lambda { |sexp|
        emit("case ")
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
        emit(" end")
      },
      :class => lambda { |sexp|
        emit("class ")
        resource(sexp[1])
        if ! void?(sexp[2])
          emit " < "
          resource(sexp[2])
        end
        emit(statement_seperator)
        resource(sexp[3]) unless void?(sexp[3])
        emit("end")
      },
      :class_name_error => NYI,
      :command => lambda { |sexp|
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
      },
      :command_call => NYI,
      :const_path_field => lambda { |sexp|
        resource(sexp[1])
        emit("::")
        resource(sexp[2])
      },
      :const_path_ref => lambda { |sexp|
        resource(sexp[1])
        emit("::")
        resource(sexp[2])
      },
      :const_ref => PASS1,
      :def => lambda { |sexp|
        emit("def ")
        resource(sexp[1])
        opt_parens(sexp[2])
        emit(statement_seperator)
        resource(sexp[3])
        emit("end")
      },
      :defined => lambda { |sexp|
        emit("defined?(")
        resource(sexp[1])
        emit(")")
      },
      :defs => NYI,
      :do_block => lambda { |sexp|
        emit(" do")
        handle_block(sexp)
        emit("end")
      },
      :dot2 => lambda { |sexp|
        resource(sexp[1])
        emit("..")
        resource(sexp[2])
      },
      :dot3 => lambda { |sexp|
        resource(sexp[1])
        emit("...")
        resource(sexp[2])
      },
      :dyna_symbol => lambda { |sexp|
        emit(':"')
        resource(sexp[1])
        emit('"')
      },
      :else => lambda { |sexp|
        emit(" else ")
        resource(sexp[1])
      },
      :elsif => lambda { |sexp|
        emit(" elsif ")
        resource(sexp[1])
        emit(" then ")
        resource(sexp[2])
        resource(sexp[3])
      },
      :ensure => lambda { |sexp|
        emit("ensure ")
        if sexp[1]
          resource(sexp[1])
          emit(statement_seperator) unless void?(sexp[1])
        end
      },
      :excessed_comma => NYI,
      :fcall => PASS1,
      :field => lambda { |sexp|
        resource(sexp[1])
        emit(sexp[2])
        resource(sexp[3])
      },
      :for => lambda { |sexp|
        emit("for ")
        resource(sexp[1])
        emit(" in ")
        resource(sexp[2])
        emit(" do ")
        unless void?(sexp[3])
          resource(sexp[3])
          emit(" ")
        end
        emit("end")
      },
      :hash => lambda { |sexp|
        emit("{")
        resource(sexp[1])
        emit("}")
      },
      :if => lambda { |sexp|
        emit("if ")
        resource(sexp[1])
        emit(" then ")
        resource(sexp[2])
        resource(sexp[3])
        emit(" end")
      },
      :if_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" if ")
        resource(sexp[1])
      },
      :ifop => lambda { |sexp|
        resource(sexp[1])
        emit(" ? ")
        resource(sexp[2])
        emit(" : ")
        resource(sexp[3])
      },
      :lambda => lambda { |sexp|
        emit("->")
        resource(sexp[1])
        emit(" {")
        if ! void?(sexp[2])
          emit(" ")
          resource(sexp[2])
        end
        emit(" ")
        emit("}")
      },
      :magic_comment => NYI,
      :massign => lambda { |sexp|
        resource(sexp[1])
        emit(" = ")
        resource(sexp[2])
      },
      :method_add_arg => lambda { |sexp|
        resource(sexp[1])
        resource(sexp[2])
      },
      :method_add_block => lambda { |sexp|
        resource(sexp[1])
        resource(sexp[2])
      },
      :mlhs_add => lambda { |sexp|
        resource(sexp[1])
        emit(", ") unless sexp[1] == [:mlhs_new]
        resource(sexp[2])
      },
      :mlhs_add_star => lambda { |sexp|
        resource(sexp[1])
        emit(", ") unless sexp[1] == [:mlhs_new]
        emit("*")
        resource(sexp[2])
      },
      :mlhs_new => NOOP,
      :mlhs_paren => lambda { |sexp|
        emit("(")
        resource(sexp[1])
        emit(")")
      },
      :module => lambda { |sexp|
        emit("module ")
        resource(sexp[1])
        if void?(sexp[2])
          emit(statement_seperator)
        else
          resource(sexp[2])
        end
        emit("end")
      },
      :mrhs_add => lambda { |sexp|
        resource(sexp[1])
        emit(", ")
        resource(sexp[2])
      },
      :mrhs_add_star => lambda { |sexp|
        resource(sexp[1])
        emit(", ")
        emit("*")
        resource(sexp[2])
      },
      :mrhs_new => NYI,
      :mrhs_new_from_args => PASS1,
      :next => lambda { |sexp|
        emit("next")
      },
      :opassign => lambda { |sexp|
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
        emit(" ")
        resource(sexp[3])
      },
      :param_error => NYI,
      :params => lambda { |sexp|
        params(sexp[1], sexp[2], sexp[3], sexp[4], sexp[5])
      },
      :paren => lambda { |sexp|
        emit("(")
        resource(sexp[1])
        emit(")")
      },
      :parse_error => NYI,
      :program => PASS1,
      :qwords_add => lambda { |sexp|
        words("w", sexp)
      },
      :qwords_new => NOOP,
      :redo => lambda { |sexp|
        emit("redo")
      },
      :regexp_literal => lambda { |sexp|
        emit("/")
        # account for [:regexp_add, [:regexp_new], [:@tstring_content, "whatever"]] structure
        # it always seems to to be the same for literals, so i don't think new handlers
        # for :regexp_add are necessary
        resource(sexp[1][2])
        emit("/")
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
            resource(sexp[3])
            emit(statement_seperator)
          end
        end
      },
      :rescue_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" rescue ")
        resource(sexp[1])
      },
      :rest_param => lambda { |sexp|
        emit("*")
        resource(sexp[1])
      },
      :retry => lambda { |sexp|
        emit("retry")
      },
      :return => lambda { |sexp|
        emit("return")
        opt_parens(sexp[1])      
      },
      :return0 => lambda { |sexp|
        emit("return")
      },
      :sclass => NYI,
      :stmts_add => lambda { |sexp|
        if sexp[1] != [:stmts_new]
          resource(sexp[1])
          emit(statement_seperator)
        end
        resource(sexp[2])
      },
      :stmts_new => NOOP,
      :string_add => lambda { |sexp|
        resource(sexp[1])
        resource(sexp[2])
      },
      :string_concat => lambda { |sexp|
        resource(sexp[1])
        emit(" ")
        resource(sexp[2])
      },
      :string_content => NOOP,
      :string_dvar => NYI,
      :string_embexpr => lambda { |sexp|
        emit('#{')
        resource(sexp[1])
        emit('}')
      },
      :string_literal => lambda { |sexp|
        emit('"')
        resource(sexp[1])
        emit('"')
      },
      :super => lambda { |sexp|
        emit("super")
        opt_parens(sexp[1])
      },
      :symbol => lambda { |sexp|
        emit(":")
        resource(sexp[1])
      },
      :symbol_literal => PASS1,
      :top_const_field => NYI,
      :top_const_ref => NYI,
      :unary => lambda { |sexp|
        emit(sexp[1].to_s[0,1])
        resource(sexp[2])
      },
      :undef => lambda { |sexp|
        emit("undef ")
        resource(sexp[1].first)
      },
      :unless => lambda { |sexp|
        emit("unless ")
        resource(sexp[1])
        emit(" then ")
        resource(sexp[2])
        resource(sexp[3])
        emit(" end")
      },
      :unless_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" unless ")
        resource(sexp[1])
      },
      :until => lambda { |sexp|
        emit("until ")
        resource(sexp[1])
        emit(" do ")
        resource(sexp[2])
        emit(" end")
      },
      :until_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" until ")
        resource(sexp[1])
      },
      :var_alias => NYI,
      :var_field => PASS1,
      :var_ref => PASS1,
      :void_stmt => NOOP,
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
        resource(sexp[2])
        emit(" end")
      },
      :while_mod => lambda { |sexp|
        resource(sexp[2])
        emit(" while ")
        resource(sexp[1])
      },
      :word_add => PASS2,
      :word_new => NOOP,
      :words_add => lambda { |sexp|
        words("W", sexp)
      },
      :words_new => NOOP,
      :xstring_add => lambda { |sexp|
        resource(sexp[1])
        resource(sexp[2])
      },
      :xstring_literal => lambda { |sexp|
        emit('"')
        resource(sexp[1])
        emit('"')
      },
      :xstring_new => NOOP,
      :yield => lambda { |sexp|
        emit("yield")
        opt_parens(sexp[1])
      },
      :yield0 => lambda { |sexp|
        emit("yield")
      },
      :zsuper => lambda { |sexp|
        emit("super")
      },
      
      # Scanner keywords
      
      :@CHAR => NYI,
      :@__end__ => NYI,
      :@backref => NYI,
      :@backtick => NYI,
      :@comma => NYI,
      :@comment => NYI,
      :@const => EMIT1,
      :@cvar => EMIT1,
      :@embdoc => NYI,
      :@embdoc_beg => NYI,
      :@embdoc_end => NYI,
      :@embexpr_beg => NYI,
      :@embexpr_end => NYI,
      :@embvar => NYI,
      :@float => EMIT1,
      :@gvar => EMIT1,
      :@heredoc_beg => NYI,
      :@heredoc_end => NYI,
      :@ident => EMIT1,
      :@ignored_nl => NYI,
      :@int => EMIT1,
      :@ivar => EMIT1,
      :@kw => EMIT1,
      :@label => NYI,
      :@lbrace => NYI,
      :@lbracket => NYI,
      :@lparen => NYI,
      :@nl => NYI,
      :@op => EMIT1,
      :@period => NYI,
      :@qwords_beg => NYI,
      :@rbrace => NYI,
      :@rbracket => NYI,
      :@regexp_beg => NYI,
      :@regexp_end => NYI,
      :@rparen => NYI,
      :@semicolon => NYI,
      :@sp => NYI,
      :@symbeg  => NYI,
      :@tlambda => NYI,
      :@tlambeg => NYI,
      :@tstring_beg => NYI,
      :@tstring_content => EMIT1,
      :@tstring_end => NYI,
      :@words_beg => NYI,
      :@words_sep => NYI,
    }
    HANDLERS[:bodystmt] = HANDLERS[:body_stmt]
  end
end
