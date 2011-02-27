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

    def method_missing meth, *args
      # check the handler for specialized handling methods
      if @handlers.respond_to? meth
        @handlers.__send__ meth, *args
      else
        raise NoMethodError, "unknown method #{meth} for #{self.class}"
      end
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
      # set the expression "cursor" information before we call the handler
      # so that it's available in the source_notify method
      @previous_expression = @current_expression if @current_expression
      @current_expression = sexp
      handler.call(self, sexp)
      @current_expression = @previous_expression
      generated_source 
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
        
    def void?(sexp)
      sexp.nil? ||
        sexp == @handlers.void_statement ||
        sexp == @handlers.void_body ||
        sexp == @handlers.void_body2
    end
  end
end
