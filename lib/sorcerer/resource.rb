#!/usr/bin/env ruby

require 'ruby-debug'
require 'active_support/core_ext'
require_relative 'handlers'

module Sorcerer

  def Sorcerer.const_missing const
    puts const
    debugger
    1
  end

  class HandlerClass
    def extend mod
      super mod
      self.singleton_class.constants.each do |c|
        c_meth = c.to_s.downcase.underscore
        self.define_singleton_method c_meth.intern do
          self.singleton_class.const_get c
        end
      end
    end
  end
  
  class Resource
    class NoHandlerError < StandardError
    end

    attr_accessor :statement_seperator

    def initialize(sexp, debug=false)
      @sexp = sexp
      @source = ''
      @debug = debug
      @word_level = 0
      @indent_level = 0
      @statement_seperator = ";"
      @indent=""
      @handlers = HandlerClass.new
    end

    def statement_seperator
      #prevent double output of the statment seperator
      if @source.end_with? @statement_seperator
        ''
      else
        @statement_seperator
      end
    end
    
    def source
      @handlers.extend Sorcerer::Handlers
      resource(@sexp)
      @source
    end

    def pretty_source
      @handlers.extend Sorcerer::PrettyHandlers
      @statement_seperator = "\n"
      @indent = "  "
      resource(@sexp)
      @source
    end

    def resource(sexp)
      return unless sexp
      handler = @handlers.handlers[sexp.first]
      raise NoHandlerError.new(sexp.first) unless handler
      if @debug
        puts "----------------------------------------------------------"
        pp sexp
      end
      handler.call(self, sexp)
    end
   
    def opt_parens(sexp)
      emit(" ") unless sexp.first == :arg_paren || sexp.first == :paren
      resource(sexp)
    end
    
    def emit(string)
      puts "EMITTING '#{string}'" if @debug
      if @source.end_with? "\n"
        @source << (@indent * @indent_level)
      end
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
