#!/usr/bin/env ruby
require_relative 'handlers_class'

require_relative 'handlers'

module Sorcerer

  class Resource
    
    class NoHandlerError < StandardError; end

    attr_accessor :statement_seperator
    attr_accessor :indent, :indent_level
    attr_accessor :current_expression, :previous_expression

    def initialize(handler_class = Source, debug=false)
      @source = ''
      @debug = debug
      @word_level = 0
      @indent_level = 0
      @statement_seperator = "; "
      @indent=""
      @handlers = handler_class.new(self)
      @current_expression = nil
      @previous_expression = nil
    end

    def handler
      @handlers
    end

    def generated_source
      @source
    end
    
    def generated_source= new_source
      @source = new_source
    end

    def statement_seperator
      #prevent double output of the statment seperator
      if @source.end_with? @statement_seperator
        ''
      else
        @statement_seperator
      end
    end

    def resource(sexp)
      return unless sexp
      handler = @handlers[sexp]
      raise NoHandlerError.new(sexp.first) unless handler
      if @debug
        puts "----------------------------------------------------------"
        pp sexp
      end
      @previous_expression = @current_expression if @current_expression
      @current_expression = sexp
      src = handler.call(self, sexp)
      @current_expression = @previous_expression
      src
    end
   
    def opt_parens(sexp)
      emit(" ") unless sexp.first == :arg_paren || sexp.first == :paren
      resource(sexp)
    end
    
    def emit(string)
      puts "EMITTING '#{string}'" if @debug
      @handlers.respond_to? :source_notify and @handlers.source_notify(string, @current_expression)
      @source << string.to_s
    end
    
    def nyi(sexp)
      raise "Handler for #{sexp.first} not implemented (#{sexp.inspect})"
    end
    
    def emit_separator(sep, first)
      emit(sep) unless first
      false
    end
    
    def emit_statement_block
      @indent_level += 1
      emit(@statement_seperator)
      yield if block_given?
      @indent_level -= 1
    end

    def handle_block(sexp)
      resource(sexp[1])     # Arguments
      if ! void?(sexp[2])
        #only necessary when we are on the same line with a do.
        #a hard coded exception
        emit(" ") unless @source.end_with? "\n"
        resource(sexp[2])     # Statements
      end
      emit(" ")
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
    
    
    def void?(sexp)
      sexp.nil? ||
        sexp == @handlers.void_statement ||
        sexp == @handlers.void_body ||
        sexp == @handlers.void_body2
    end
  end
end
