#!/usr/bin/env ruby
require_relative 'handlers_class'

require_relative 'handlers'

module Sorcerer

  class Resource
    
    class NoHandlerError < StandardError; end

    attr_accessor :statement_seperator
    attr_accessor :indent, :indent_level, :word_level
    attr_accessor :current_expression, :previous_expression

    def initialize(handler_class = Source, debug=false)
      @source = ''
      @debug = debug
      @word_level = 0
      @indent_level = 0
      @statement_seperator = "; "
      @indent=""
      @handlerobj = handler_class.new(self)
      @current_expression = nil
      @previous_expression = nil
    end

    def const_missing c
      puts "looking for #{c}"
      @handlerobj.class.const_get c
    end

    def method_missing meth, *args
      # check the handler for specialized handling methods
      if @handlerobj.respond_to? meth
        @handlerobj.__send__ meth, *args
      else
        raise NoMethodError, "unknown method #{meth} for #{self.class}"
      end
    end

    def handler
      @handlerobj
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
      handler = @handlerobj[sexp]
      raise NoHandlerError.new(sexp.first) unless handler
      if @debug
        puts "----------------------------------------------------------"
        pp sexp
      end
      # set the expression "cursor" information before we call the handler
      # so that it's available in the source_notify method
      @previous_expression = @current_expression if @current_expression
      @current_expression = sexp
      @handlerobj.instance_exec sexp, &handler
      @current_expression = @previous_expression
      generated_source 
    end
   
    def emit(string)
      puts "EMITTING '#{string}'" if @debug
      @handlerobj.respond_to? :source_notify and @handlerobj.source_notify(string, @current_expression)
      @source << string.to_s
    end
    
    def nyi(sexp)
      raise "Handler for #{sexp.first} not implemented (#{sexp.inspect})"
    end
    
    def void?(sexp)
      sexp.nil? ||
        sexp == VOID_STATEMENT ||
        sexp == VOID_BODY ||
        sexp == VOID_BODY2
    end
  end
end
