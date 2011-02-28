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

    def HandlerClass.handlers
      if block_given?
        #jump through hoops to avoid
        #constant reassignment warnings
        handlers = HANDLERS
        new_handlers = yield handlers 
        HANDLERS.clear
        HANDLERS.merge! new_handlers
      else
        HANDLERS
      end
    end

    # So, the big question is why the hell are all these things constants?  The
    # answer is that we want Inheritable Class Values which are accessible from
    # an instance.  Constants solves this problem nicely.
    #
    # Type             |Inheritable | Class Specific | Instance Accessible
    # –-------------------------------------------------------------------
    # Eigenclass iVars |            |       X        |   X (with method)
    # Class Vars       |    X       |                |         X
    # Instance Vars    |            |       X        |         X
    # Constants        |    X       |       X        |   X (with method)
    #
    # We can create accessor for the constants if we want (although it's 
    # possible to look them up from outside of the class with the :: syntax.)
    #
    # Because of the way that constant lookup works, it's possible you could
    # get some weird effects if you define a handler class in a non-top level
    # static scope - sooo... don't do that.
    #
    # Plus, we don't want to require active support, and class_inheritable
    # accessor doesn't really work all that great.

    VOID_STATEMENT = [:stmts_add, [:stmts_new], [:void_stmt]]
    VOID_BODY = [:body_stmt, VOID_STATEMENT, nil, nil, nil]
    VOID_BODY2 = [:bodystmt, VOID_STATEMENT, nil, nil, nil]
   
    NYI = lambda { |sexp| nyi(sexp) }
    DBG = lambda { |sexp| pp(sexp) }
    NOOP = lambda { |sexp| }
    SPACE = lambda { |sexp| emit(" ") }
    PASS1 = lambda { |sexp| resource(sexp[1]) }
    PASS2 = lambda { |sexp| resource(sexp[2]) }
    EMIT1 = lambda { |sexp| emit(sexp[1]) }
    HANDLERS = {}

    def initialize(res_object)
      @resource_obj = res_object
      self.class.constants.each do |p|
        self.class.__send__ :define_method, p.downcase.intern do
          self.class.const_get p
        end
      end
    end
    
    attr_accessor :resource_obj
    def_delegators :@resource_obj, :statement_seperator, :indent, :resource,
      :generated_source, :statement_seperator=, :indent= , :indent_level,
      :emit, :word_level, :word_level=, :void?
    
    def source_watch &block
      raise ArgumentError, "Block required for source watch" unless block_given?
      raise ArgumentError, "Block should take the proposed addition \
      and the current S-Exp as arguments" unless block.arity == 2 
      @notify_blocks ||= {} 
      @notify_blocks << block
      unless self.methods.include? :source_notify
        self.class.__send__ :define_method, :source_notify do |string,sexp|
          @notify_blocks.each do |b|
            b.call(string,sexp)
          end
        end
      end
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
