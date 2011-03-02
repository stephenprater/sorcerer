require_relative 'handlers'


class String
  #because i can't believe this doen't exist already
  def matches(pattern)
    Enumerator.new do |y|
      self.scan(pattern) do
        y << Regexp.last_match
      end
    end
  end
end
        


      
module Sorcerer
  class PrettySource < Sorcerer::Source
    # a list of words which appear at the same
    # indent level as their "begin" word.
    #

    DOUBLE_BREAK = ["class","module","def"]
    # there are more of these, but these are the
    # most common - techincally any operator or
    # comma can break a line
    
    # ha - the second one cathes || too.
    BREAKABLE_PATTERNS = [/,/,/(\|.*?\|)/,/&&/,/\+/]
    def pretty_source(sexp, *opts)
      debug = (opts.include? :debug) ? true : false
      trailing_new_line = (opts & [:trailing_newline,:tnl]).length >= 1 ? true : false
      #barewords are always local
      @since_last_nl = 0
      self.statement_seperator = "\n"
      self.indent = "  "

      if debug
        resource_obj.instance_eval do
          @debug = true
        end
      end
     
      #sources watchers are executed in the order they are defined
      #add extra lines before class, modules, and defs.
      source_watch do |string,exp|
        next if generated_source.length == 0
        emit_double_line if DOUBLE_BREAK.include? string 
      end

      # break the line if we're longer than 80 chars
      source_watch do |string, exp|
        if string == "\n"
          @since_last_nl = 0
          next
        else
          @since_last_nl += string.length
        end

        if @since_last_nl > 80
          # search backwards for the last (first?) breakable character
          bl = generated_source.length - @since_last_nl
          BREAKABLE_PATTERNS.each do |char|
            #position of the last matching breakable
            cand = generated_source.matches(char).to_a.last.end(0) rescue 0
            bl = cand > bl ? cand : bl
          end
          puts "breaking at #{bl} on"
          generated_source.insert(bl,"\n #{indent * indent_level}")
          @since_last_nl = 0
        end
      end
        
      # add the indents
      source_watch do |string, exp|
        if generated_source.end_with? statement_seperator
          next if string.length == 0
          generated_source << (indent * indent_level) # that ought to work
        end
      end
      

      unless trailing_new_line
        resource(sexp) 
      else
        resource(sexp) << "\n"
      end
    end
    teach_spell :pretty_source

    def emit_statement_block 
      emit(statement_seperator)
      self.indent_level += 1 
      yield if block_given?
      self.indent_level -= 1 
      emit(statement_seperator)
    end

    def emit_double_line
      # no, i really mean it.
      generated_source << "\n"
    end
    
    def emit_space
      generated_source << " "
    end

    def emit string, *opts 
      supress_indent = (opts & [:no_indent, :supress_indent]).length >= 1 ? true : false
      with_space = (opts & [:with_space, :trailing_space]).length >= 1 ? true : false 
      self.indent_level -= 1 if supress_indent 
      super string
      generated_source << " " if with_space
      self.indent_level += 1 if supress_indent
    end

    def opt_parens(sexp)
      if sexp.any?
        super(sexp)
      end
    end

    handlers do |hs|
      hs.merge({
      # parser keywords
      :BEGIN => lambda { |sexp|
        emit("BEGIN {")
        unless void?(sexp[1])
          emit_space 
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
        emit("class", :with_space)
        resource(sexp[1])
        if ! void?(sexp[2])
          emit " < "
          resource(sexp[2])
        end
        unless void?(sexp[3])
          emit_statement_block do
            resource(sexp[3]) 
          end
        else
          emit(";", :with_space)
        end
        emit("end")
      },
      :sclass => lambda { |sexp|
        emit("class ") 
        emit("<< ")
        resource(sexp[1])
        unless void?(sexp[2])
          emit_statement_block do
            resource(sexp[2])
          end
        else
          # i don't know why you would do this, but the
          # case is accounted for
          emit(";", :with_space)
        end
        emit("end")
      },
      :def => lambda { |sexp|
        emit("def", :with_space)
        resource(sexp[1])
        opt_parens(sexp[2])
        unless void?(sexp[3])
          emit_statement_block do
            resource(sexp[3])
          end
        else
          emit(";", :with_space)
        end
        emit("end")
      },
      :unless => lambda { |sexp|
        emit("unless", :with_space)
        resource(sexp[1])
        emit(" then")
        emit_statement_block do
          resource(sexp[2])
        end
        resource(sexp[3])
        emit("end")
      },
      :if => lambda { |sexp| 
        emit("if", :with_space)
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
        emit("elsif", :with_space)
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
        emit("module", :with_space)
        resource(sexp[1])
        unless void?(sexp[2])
          emit_statement_block do
            resource(sexp[2])
          end
        else
          emit(";", :with_space)
        end
        emit("end")
      },
      :rescue => lambda { |sexp|
        emit("rescue",:no_indent)
        if sexp[1]                # Exception list
          emit_space
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
            emit(statement_seperator)
            resource(sexp[3])
            emit(statement_seperator)
          end
        end
      },
      :ensure => lambda { |sexp|
        emit("ensure",:no_indent)
        if sexp[1]
          unless void?(sexp[1]) 
            emit(statement_seperator)
            resource(sexp[1])
            emit(statement_seperator) 
          end
        end
      },
      :until => lambda { |sexp|
        emit("until",:with_space)
        resource(sexp[1])
        emit(" do")
        emit_statement_block do 
          resource(sexp[2])
        end
        emit("end")
      },
      :case => lambda { |sexp|
        emit("case", :with_space)
        resource(sexp[1]) # variable
        emit_statement_block do 
          resource(sexp[2])
        end
        emit("end")
      },
     :when => lambda { |sexp|
        emit("when",:with_space)
        resource(sexp[1])
        emit_statement_block do
          resource(sexp[2])
        end
        if sexp[3]
          resource(sexp[3])      
        end
      },
      :while => lambda { |sexp|
        emit("while",:with_space)
        resource(sexp[1])
        emit(" do")
        emit_statement_block do
          resource(sexp[2])
        end
        emit("end")
      },
      :for => lambda { |sexp|
        emit("for",:with_space)
        resource(sexp[1])
        emit(" in", :with_space)
        resource(sexp[2])
        emit(" do")
        unless void?(sexp[3])
          emit_statement_block do
            resource(sexp[3])
          end
        else
          emit_space
        end
        emit("end")
      }})
    end
  end
end
