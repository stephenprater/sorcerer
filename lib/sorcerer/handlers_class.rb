require 'forwardable'

require_relative 'minimal_match'

module Sorcerer
  class HandlerClass
    extend Forwardable

    def HandlerClass.teach_spell method
      handler_class = self
      Sorcerer.singleton_class.__send__ :define_method, method do |sexp, debug = false|
        res = Sorcerer::Resource.new(handler_class,debug)
        res.handler.__send__(method, sexp)
      end
    end
   
    def initialize(res_object)
      @resource_obj = res_object 
    end
    
    attr_accessor :resource_obj
    def_delegators :@resource_obj, :statement_seperator, :indent, :resource, :generated_source,
      :statement_seperator=, :indent= , :indent_level
    
    [:VOID_STATEMENT,:VOID_BODY,:VOID_BODY2,:NYI,:DBG,
    :NOOP,:SPACE,:PASS1,:PASS2,:EMIT1,:HANDLERS].each do |c|
      c_meth = c.to_s.downcase
      define_method c_meth.intern do
        self.class.const_get c
      end
    end

    def source_watch &block
      raise ArgumentError, "Block required for source watch" unless block_given?
      raise ArgumentError, "Block should take the proposed addition \
      and the current S-Exp as arguments" unless block.arity == 2 
      self.class.send :define_method, :source_notify, &block
    end
    
    def [] sexp 
      unless @key_cache
        @key_cache = {}

        all_keys = handlers.keys
        @key_cache[:multi] = all_keys.select do |k|
          k.is_a? Array
        end
      end
      sexp.extend MinimalMatch if @key_cache[:multi].length > 0 
      
      @key_cache[:multi].each do |k|
        return handlers[k] if sexp =~ k
      end
      handlers[sexp.first] or nil
    end
  end
end
