#!/usr/local/bin/ruby

# Parse a Ruby source file, building a set of objects
# representing the modules, classes, methods,
# requires, and includes we find (these classes
# are defined in code_objects.rb).

class RubyLex
  attr_reader :reader
  class BufferedReader
    attr_reader :content
  end
end

# This file contains stuff stolen outright from:
#
#   rtags.rb - 
#   ruby-lex.rb - ruby lexcal analizer
#   ruby-token.rb - ruby tokens 
#   	by Keiju ISHITSUKA (Nippon Rational Inc.)

# Extract code elements from a source file, returning a TopLevel
# object containing the constituent file elements.
#
# This file is based on rtags

module RDoc

  GENERAL_MODIFIERS = [ 'nodoc' ].freeze

  CLASS_MODIFIERS = GENERAL_MODIFIERS

  ATTR_MODIFIERS  = GENERAL_MODIFIERS

  CONSTANT_MODIFIERS = GENERAL_MODIFIERS

  METHOD_MODIFIERS = GENERAL_MODIFIERS + 
    [ 'arg', 'args', 'yield', 'yields', 'notnew', 'not-new', 'not_new', 'doc' ]


  class RubyParser
    include RubyToken
    include TokenStream

    extend ParserFactory

    parse_files_matching(/\.rbw?$/)


    def initialize(top_level, file_name, content, options, stats)
      @options = options
      @stats   = stats
      @size = 0
      @token_listeners = nil
      @input_file_name = file_name
      @scanner = RubyLex.new(content)
      @scanner.exception_on_syntax_error = false
      @top_level = top_level
      @progress = $stderr unless options.quiet
    end

    def scan
      @tokens = []
      @unget_read = []
      @read = []
      catch(:eof) do
        catch(:enddoc) do
          begin
            parse_toplevel_statements(@top_level)
          rescue Exception => e
            $stderr.puts "\n\n"
            $stderr.puts "RDoc failure in #@input_file_name at or around " +
                         "line #{@scanner.line_no} column #{@scanner.char_no}"
            $stderr.puts 
            $stderr.puts "Before reporting this, could you check that the file"
            $stderr.puts "you're documenting compiles cleanly--RDoc is not a"
            $stderr.puts "full Ruby parser, and gets confused easily if fed"
            $stderr.puts "invalid programs."
            $stderr.puts
            $stderr.puts "The internal error was:\n\n"
            
            e.set_backtrace(e.backtrace[0,4])
            raise
          end
        end
      end
      @top_level
    end

    private 

    def make_message(msg)
      prefix = "\n" + @input_file_name + ":"
      if @scanner
        prefix << "#{@scanner.line_no}:#{@scanner.char_no}: "
      end
      return prefix + msg
    end

    def warn(msg)
      return if @options.quiet
      msg = make_message msg
      $stderr.puts msg
    end

    def error(msg)
      msg = make_message msg
      $stderr.puts msg
      exit(1)
    end

    def progress(char)
      unless @options.quiet
        @progress.print(char)
	@progress.flush
      end
    end

    def add_token_listener(obj)
      @token_listeners ||= []
      @token_listeners << obj
    end

    def remove_token_listener(obj)
      @token_listeners.delete(obj)
    end

    def get_tk
      tk = nil
      if @tokens.empty?
	tk = @scanner.token
	@read.push @scanner.get_read
	puts "get_tk1 => #{tk.inspect}" if $TOKEN_DEBUG
      else
	@read.push @unget_read.shift
	tk = @tokens.shift
	puts "get_tk2 => #{tk.inspect}" if $TOKEN_DEBUG
      end

      if tk.kind_of?(TkSYMBEG)
        set_token_position(tk.line_no, tk.char_no)
        tk1 = get_tk
        if tk1.kind_of?(TkId) || tk1.kind_of?(TkOp)
          tk = Token(TkSYMBOL).set_text(":" + tk1.name)
          # remove the identifier we just read (we're about to
          # replace it with a symbol)
          @token_listeners.each do |obj|
            obj.pop_token
          end if @token_listeners
        else
          warn("':' not followed by identifier or operator")
          tk = tk1
        end
      end

      # inform any listeners of our shiny new token
      @token_listeners.each do |obj|
        obj.add_token(tk)
      end if @token_listeners

      tk
    end

    def peek_tk
      unget_tk(tk = get_tk)
      tk
    end

    def unget_tk(tk)
      @tokens.unshift tk
      @unget_read.unshift @read.pop

      # Remove this token from any listeners
      @token_listeners.each do |obj|
        obj.pop_token
      end if @token_listeners
    end

    def skip_tkspace(skip_nl = true)
      tokens = []
      while ((tk = get_tk).kind_of?(TkSPACE) ||
	     (skip_nl && tk.kind_of?(TkNL)))
	tokens.push tk
      end
      unget_tk(tk)
      tokens
    end

    def get_tkread
      read = @read.join("")
      @read = []
      read
    end

    def peek_read
      @read.join('')
    end

    NORMAL = "::"
    SINGLE = "<<"

    # Look for the first comment in a file that isn't
    # a shebang line.

    def collect_first_comment
      skip_tkspace
      res = ''
      first_line = true

      tk = get_tk
      while tk.kind_of?(TkCOMMENT)
        if first_line && tk.text[0,2] == "#!"
          skip_tkspace
          tk = get_tk
        else
          res << tk.text << "\n"
          tk = get_tk
          if tk.kind_of? TkNL
            skip_tkspace(false)
            tk = get_tk
          end
        end
        first_line = false
      end
      unget_tk(tk)
      res
    end

    def parse_toplevel_statements(container)
      comment = collect_first_comment
      look_for_directives_in(container, comment)
      container.comment = comment unless comment.empty?
      parse_statements(container, NORMAL, nil, comment)
    end
    
    def parse_statements(container, single=NORMAL, current_method=nil, comment='')
      nest = 1
      save_visibility = container.visibility
      
#      if container.kind_of?(TopLevel)
#      else
#        comment = ''
#      end

      non_comment_seen = true
      
      while tk = get_tk
        
        keep_comment = false
        
        non_comment_seen = true unless tk.kind_of?(TkCOMMENT)
        
	case tk

        when TkNL
          skip_tkspace(true)   # Skip blanks and newlines
          tk = get_tk
          if tk.kind_of?(TkCOMMENT)
            if non_comment_seen
              comment = ''
              non_comment_seen = false
            end
            while tk.kind_of?(TkCOMMENT)
              comment << tk.text << "\n"
              tk = get_tk          # this is the newline 
              skip_tkspace(false)  # leading spaces
              tk = get_tk
            end
            unless comment.empty?
              look_for_directives_in(container, comment) 
              if container.done_documenting
                container.ongoing_visibility = save_visibility
#                return
              end
            end
            keep_comment = true
          else
            non_comment_seen = true
          end
          unget_tk(tk)
          keep_comment = true


	when TkCLASS
	  if container.document_children
            parse_class(container, single, tk, comment)
	  else
	    nest += 1
          end

	when TkMODULE
	  if container.document_children
            parse_module(container, single, tk, comment)
	  else
	    nest += 1
          end

	when TkDEF
	  if container.document_self
	    parse_method(container, single, tk, comment)
	  else
	    nest += 1
          end

        when TkCONSTANT
          if container.document_self
            parse_constant(container, single, tk, comment)
          end

	when TkALIAS
 	  if container.document_self
	    parse_alias(container, single, tk, comment)
	  end

        when TkYIELD
          if current_method.nil?
            warn("Warning: yield outside of method") if container.document_self
          else
            parse_yield(container, single, tk, current_method)
          end

          # Until and While can have a 'do', which shouldn't increas
          # the nesting. We can't solve the general case, but we can
          # handle most occurrences by ignoring a do at the end of a line

        when  TkUNTIL, TkWHILE
          nest += 1
          puts "FOUND #{tk.class} in #{container.name}, nest = #{nest}, " +
            "line #{tk.line_no}" if $DEBUG
          skip_optional_do_after_expression

          # 'for' is trickier
        when TkFOR
          nest += 1
          puts "FOUND #{tk.class} in #{container.name}, nest = #{nest}, " +
            "line #{tk.line_no}" if $DEBUG
          skip_for_variable
          skip_optional_do_after_expression

	when TkCASE, TkDO, TkIF, TkUNLESS, TkBEGIN
	  nest += 1
          puts "Found #{tk.class} in #{container.name}, nest = #{nest}, " +
            "line #{tk.line_no}" if $DEBUG

	when TkIDENTIFIER
          if nest == 1 and current_method.nil?
            case tk.name
            when "private", "protected", "public",
                 "private_class_method", "public_class_method"
              parse_visibility(container, single, tk)
              keep_comment = true
            when "attr"
              parse_attr(container, single, tk, comment)
            when /^attr_(reader|writer|accessor)$/, @options.extra_accessors
              parse_attr_accessor(container, single, tk, comment)
            when "alias_method"
              if container.document_self
	        parse_alias(container, single, tk, comment)
	      end
            end
	  end
	  
	  case tk.name
	  when "require"
	    parse_require(container, comment)
	  when "include"
	    parse_include(container, comment)
	  end


	when TkEND
          nest -= 1
          puts "Found 'end' in #{container.name}, nest = #{nest}, line #{tk.line_no}" if $DEBUG
          puts "Method = #{current_method.name}" if $DEBUG and current_method
	  if nest == 0
            read_documentation_modifiers(container, CLASS_MODIFIERS)
            container.ongoing_visibility = save_visibility
            return
          end

	end

        comment = '' unless keep_comment
	begin
	  get_tkread
	  skip_tkspace(false)
	end while peek_tk == TkNL

      end
    end
    
    def parse_class(container, single, tk, comment, &block)
      progress("c")
      @stats.num_classes += 1
      container, name_t = get_class_or_module(container)
      case name_t
      when TkCONSTANT
	      name = name_t.name
        superclass = "Object"

        if peek_tk.kind_of?(TkLT)
          get_tk
          skip_tkspace(true)
          superclass = get_class_specification
          superclass = "<unknown>" if superclass.empty?
        end

      	if single == SINGLE
      	  cls_type = SingleClass
      	else
      	  cls_type = NormalClass
      	end

        cls = container.add_class(cls_type, name, superclass)
       
        read_documentation_modifiers(cls, CLASS_MODIFIERS)
        cls.record_location(@top_level)
	parse_statements(cls)
        cls.comment = comment
        unless comment.empty?
           cls.file, cls.line =  @top_level.file_absolute_name, @scanner.reader.content.split("\n")[tk.line_no - 1]
        end

      when TkLSHFT
    	  case name = get_class_specification
         when "self", container.name
      	   parse_statements(container, SINGLE, &block)
      	else
        other = TopLevel.find_class_named(name)
        unless other
  #            other = @top_level.add_class(NormalClass, name, nil)
  #            other.record_location(@top_level)
  #            other.comment = comment
          other = NormalClass.new("Dummy", nil)
        end
        read_documentation_modifiers(other, CLASS_MODIFIERS)
        parse_statements(other, SINGLE, &block)
	      end

      else
	warn("Expected class name or '<<'. Got #{name_t.class}: #{name_t.text.inspect}")
      end
    end

    def parse_module(container, single, tk, comment)
      progress("m")
      @stats.num_modules += 1
      container, name_t  = get_class_or_module(container)
#      skip_tkspace
      name = name_t.name
      mod = container.add_module(NormalModule, name)
      mod.record_location(@top_level)
      read_documentation_modifiers(mod, CLASS_MODIFIERS)
      parse_statements(mod)
      mod.comment = comment
      unless comment.empty?
        mod.file, mod.line = @top_level.file_absolute_name, @scanner.reader.content.split("\n")[tk.line_no - 1]
      end
    end

    # Look for the name of a class of module (optionally with a leading :: or
    # with :: separated named) and return the ultimate name and container

    def get_class_or_module(container)
      skip_tkspace
      name_t = get_tk
      # class ::A -> A is in the top level
      if name_t.kind_of?(TkCOLON2)
        name_t = get_tk
        container = @top_level
      end

      skip_tkspace(false)

      while peek_tk.kind_of?(TkCOLON2)
        prev_container = container
        container = container.find_module_named(name_t.name)
        if !container
#          warn("Couldn't find module #{name_t.name}")
          container = prev_container.add_module(NormalModule, name_t.name)
        end
        get_tk
        name_t = get_tk
      end
      skip_tkspace(false)
      return [container, name_t]
    end

    def parse_constant(container, single, tk, comment)
      name = tk.name
      skip_tkspace(false)
      eq_tk = get_tk

      unless eq_tk.kind_of?(TkASSIGN)
        unget_tk(eq_tk)
        return
      end


      nest = 0
      get_tkread

      tk = get_tk
      if tk.kind_of? TkGT
        unget_tk(tk)
        unget_tk(eq_tk)
        return
      end

      loop do
        puts("Param: #{tk}, #{@scanner.continue} " +
          "#{@scanner.lex_state} #{nest}")  if $DEBUG

        case tk
        when TkSEMICOLON
          break
        when TkLPAREN, TkfLPAREN
          nest += 1
        when TkRPAREN
          nest -= 1
        when TkCOMMENT
          if nest <= 0 && @scanner.lex_state == EXPR_END
            unget_tk(tk)
            break
          end
        when TkNL
          if (@scanner.lex_state == EXPR_END and nest <= 0) || !@scanner.continue
            unget_tk(tk)
            break
          end
        end
        tk = get_tk
      end

      res = get_tkread.tr("\n", " ").strip
      res = "" if res == ";"
      con = Constant.new(name, res, comment)
      con.file = @top_level.file_absolute_name
       
      read_documentation_modifiers(con, CONSTANT_MODIFIERS)
      if con.document_self
	container.add_constant(con)
      end
    end

    def parse_method(container, single, tk, comment)
      progress(".")
      @stats.num_methods += 1
      line_no = tk.line_no
      column  = tk.char_no
      
      start_collecting_tokens
      add_token(tk)
      add_token_listener(self)
      
      @scanner.instance_eval{@lex_state = EXPR_FNAME}
      skip_tkspace(false)
      name_t = get_tk
      back_tk = skip_tkspace
      meth = nil
      added_container = false

      dot = get_tk
      if dot.kind_of?(TkDOT) or dot.kind_of?(TkCOLON2)
	@scanner.instance_eval{@lex_state = EXPR_FNAME}
	skip_tkspace
	name_t2 = get_tk
	case name_t
	when TkSELF
	  name = name_t2.name
	when TkCONSTANT
          name = name_t2.name
          prev_container = container
          container = container.find_module_named(name_t.name)
          if !container
            added_container = true
            obj = name_t.name.split("::").inject(Object) do |state, item|
              state.const_get(item)
            end rescue nil

            type = obj.class == Class ? NormalClass : NormalModule
            if not [Class, Module].include?(obj.class)
              warn("Couldn't find #{name_t.name}. Assuming it's a module")
            end

            if type == NormalClass then
              container = prev_container.add_class(type, name_t.name, obj.superclass.name)
            else
              container = prev_container.add_module(type, name_t.name)
            end
          end
	else
	  # warn("Unexpected token '#{name_t2.inspect}'")
	  # break
          skip_method(container)
          return
	end
	meth =  AnyMethod.new(get_tkread, name)
        meth.singleton = true
      else
	unget_tk dot
	back_tk.reverse_each do
	  |tk|
	  unget_tk tk
	end
	name = name_t.name

        meth =  AnyMethod.new(get_tkread, name)
        meth.singleton = (single == SINGLE)
      end
      
      meth.comment = comment
      meth.file = @top_level.file_absolute_name
      
      remove_token_listener(self)
        
      meth.start_collecting_tokens
      indent = TkSPACE.new(1,1)
      indent.set_text(" " * column)

      meth.add_tokens([TkCOMMENT.new(line_no,
                                     1,
                                     "# File #{@top_level.file_absolute_name}, line #{line_no}"),
                        NEWLINE_TOKEN,
                        indent])

      meth.add_tokens(@token_stream)

      add_token_listener(meth)

      @scanner.instance_eval{@continue = false}
      parse_method_parameters(meth)

      if meth.document_self
        container.add_method(meth)
      elsif added_container
        container.document_self = false
      end

      # Having now read the method parameters and documentation modifiers, we
      # now know whether we have to rename #initialize to ::new

      if name == "initialize" && !meth.singleton
        if meth.dont_rename_initialize
          meth.visibility = :protected
        else
          meth.singleton = true
          meth.name = "new"
          meth.visibility = :public
        end
      end
      
      parse_statements(container, single, meth)
      
      remove_token_listener(meth)

      # Look for a 'call-seq' in the comment, and override the
      # normal parameter stuff

      if comment.sub!(/:?call-seq:(.*?)^\s*\#?\s*$/m, '')
        seq = $1
        seq.gsub!(/^\s*\#\s*/, '')
        meth.call_seq = seq
      end


    end
    
    def skip_method(container)
      meth =  AnyMethod.new("", "anon")
      parse_method_parameters(meth)
      parse_statements(container, false, meth)
    end
    
    # Capture the method's parameters. Along the way,
    # look for a comment containing 
    #
    #    # yields: ....
    #
    # and add this as the block_params for the method

    def parse_method_parameters(method)
      res = parse_method_or_yield_parameters(method)
      res = "(" + res + ")" unless res[0] == ?(
      method.params = res unless method.params
      if method.block_params.nil?
          skip_tkspace(false)
	  read_documentation_modifiers(method, METHOD_MODIFIERS)
      end
    end

    def parse_method_or_yield_parameters(method=nil, modifiers=METHOD_MODIFIERS)
      skip_tkspace(false)
      tk = get_tk

      # Little hack going on here. In the statement
      #  f = 2*(1+yield)
      # We see the RPAREN as the next token, so we need
      # to exit early. This still won't catch all cases
      # (such as "a = yield + 1"
      end_token = case tk
                  when TkLPAREN, TkfLPAREN
                    TkRPAREN
                  when TkRPAREN
                    return ""
                  else
                    TkNL
                  end
      nest = 0

      loop do
        puts("Param: #{tk.inspect}, #{@scanner.continue} " +
          "#{@scanner.lex_state} #{nest}")  if $DEBUG
        case tk
        when TkSEMICOLON
          break
        when TkLBRACE
          nest += 1
        when TkRBRACE
          # we might have a.each {|i| yield i }
          unget_tk(tk) if nest.zero?
          nest -= 1
          break if nest <= 0
        when TkLPAREN, TkfLPAREN
          nest += 1
        when end_token
          if end_token == TkRPAREN
            nest -= 1
            break if @scanner.lex_state == EXPR_END and nest <= 0
          else
            break unless @scanner.continue
          end
        when method && method.block_params.nil? && TkCOMMENT
	  unget_tk(tk)
	  read_documentation_modifiers(method, modifiers)
        end
        tk = get_tk
      end
      res = get_tkread.tr("\n", " ").strip
      res = "" if res == ";"
      res
    end

    # skip the var [in] part of a 'for' statement
    def skip_for_variable
      skip_tkspace(false)
      tk = get_tk
      skip_tkspace(false)
      tk = get_tk
      unget_tk(tk) unless tk.kind_of?(TkIN)
    end

    # while, until, and for have an optional 
    def skip_optional_do_after_expression
      skip_tkspace(false)
      tk = get_tk
      case tk
      when TkLPAREN, TkfLPAREN
        end_token = TkRPAREN
      else
        end_token = TkNL
      end

      nest = 0
      @scanner.instance_eval{@continue = false}

      loop do
        puts("\nWhile: #{tk}, #{@scanner.continue} " +
          "#{@scanner.lex_state} #{nest}") if $DEBUG
        case tk
        when TkSEMICOLON
          break
        when TkLPAREN, TkfLPAREN
          nest += 1
        when TkDO
          break if nest.zero?
        when end_token
          if end_token == TkRPAREN
            nest -= 1
            break if @scanner.lex_state == EXPR_END and nest.zero?
          else
            break unless @scanner.continue
          end
        end
        tk = get_tk
      end
      skip_tkspace(false)
      if peek_tk.kind_of? TkDO
        get_tk
      end
    end
    
    # Return a superclass, which can be either a constant
    # of an expression

    def get_class_specification
      tk = get_tk
      return "self" if tk.kind_of?(TkSELF)
        
      res = ""
      while tk.kind_of?(TkCOLON2) ||
          tk.kind_of?(TkCOLON3)   ||
          tk.kind_of?(TkCONSTANT)   
        
        res += tk.text
        tk = get_tk
      end

      unget_tk(tk)
      skip_tkspace(false)

      get_tkread # empty out read buffer

      tk = get_tk

      case tk
      when TkNL, TkCOMMENT, TkSEMICOLON
        unget_tk(tk)
        return res
      end

      res += parse_call_parameters(tk)
      res
    end

    def parse_call_parameters(tk)

      end_token = case tk
                  when TkLPAREN, TkfLPAREN
                    TkRPAREN
                  when TkRPAREN
                    return ""
                  else
                    TkNL
                  end
      nest = 0

      loop do
        puts("Call param: #{tk}, #{@scanner.continue} " +
          "#{@scanner.lex_state} #{nest}") if $DEBUG
        case tk
        when TkSEMICOLON
          break
        when TkLPAREN, TkfLPAREN
          nest += 1
        when end_token
          if end_token == TkRPAREN
            nest -= 1
            break if @scanner.lex_state == EXPR_END and nest <= 0
          else
            break unless @scanner.continue
          end
        when TkCOMMENT
	  unget_tk(tk)
	  break
        end
        tk = get_tk
      end
      res = get_tkread.tr("\n", " ").strip
      res = "" if res == ";"
      res
    end


    # Parse a constant, which might be qualified by
    # one or more class or module names

    def get_constant
      res = ""
      skip_tkspace(false)
      tk = get_tk

      while tk.kind_of?(TkCOLON2) ||
          tk.kind_of?(TkCOLON3)   ||
          tk.kind_of?(TkCONSTANT)          
        
        res += tk.text
        tk = get_tk
      end

#      if res.empty?
#        warn("Unexpected token #{tk} in constant")
#      end 
      unget_tk(tk)
      res
    end

    # Get a constant that may be surrounded by parens
    
    def get_constant_with_optional_parens
      skip_tkspace(false)
      nest = 0
      while (tk = peek_tk).kind_of?(TkLPAREN)  || tk.kind_of?(TkfLPAREN)
        get_tk
        skip_tkspace(true)
        nest += 1
      end

      name = get_constant

      while nest > 0
        skip_tkspace(true)
        tk = get_tk
        nest -= 1 if tk.kind_of?(TkRPAREN)
      end
      name
    end

    # Directives are modifier comments that can appear after class, module,
    # or method names. For example
    #
    #   def fred    # :yields:  a, b
    #
    # or
    #
    #   class SM  # :nodoc:
    #
    # we return the directive name and any parameters as a two element array
    
    def read_directive(allowed)
      tk = get_tk
      puts "directive: #{tk.inspect}" if $DEBUG
      result = nil
      if tk.kind_of?(TkCOMMENT) 
        if tk.text =~ /\s*:?(\w+):\s*(.*)/
          directive = $1.downcase
          if allowed.include?(directive)
            result = [directive, $2]
          end
        end
      else
        unget_tk(tk)
      end
      result
    end

    
    def read_documentation_modifiers(context, allow)
      dir = read_directive(allow)

      case dir[0]

      when "notnew", "not_new", "not-new"
        context.dont_rename_initialize = true

      when "nodoc"
        context.document_self = false
	if dir[1].downcase == "all"
	  context.document_children = false
	end

      when "doc"
        context.document_self = true
        context.force_documentation = true

      when "yield", "yields"
        unless context.params.nil?
          context.params.sub!(/(,|)\s*&\w+/,'') # remove parameter &proc
        end
	context.block_params = dir[1]

      when "arg", "args"
        context.params = dir[1]
      end if dir
    end

    
    # Look for directives in a normal comment block:
    #
    #   #--       - don't display comment from this point forward
    #  
    #
    # This routine modifies it's parameter

    def look_for_directives_in(context, comment)

      preprocess = SM::PreProcess.new(@input_file_name,
                                      @options.rdoc_include)

      preprocess.handle(comment) do |directive, param|
        case directive
        when "stopdoc"
          context.stop_doc
          ""
        when "startdoc"
          context.start_doc
          context.force_documentation = true
          ""

        when "enddoc"
          #context.done_documenting = true
          #""
          throw :enddoc

        when "main"
          options = Options.instance
          options.main_page = param
	  ""

        when "title"
          options = Options.instance
          options.title = param
          ""

        when "section"
          context.set_current_section(param, comment)
          comment.replace("") # 1.8 doesn't support #clear
          break 
        else
          warn "Unrecognized directive '#{directive}'"
          break
        end
      end

      remove_private_comments(comment)
    end

    def remove_private_comments(comment)
      comment.gsub!(/^#--.*?^#\+\+/m, '')
      comment.sub!(/^#--.*/m, '')
    end



    def get_symbol_or_name
      tk = get_tk
      case tk
      when  TkSYMBOL
        tk.text.sub(/^:/, '')
      when TkId, TkOp
        tk.name
      when TkSTRING
        tk.text
      else
        raise "Name or symbol expected (got #{tk})"
      end
    end
    
    def parse_alias(context, single, tk, comment)
      skip_tkspace
      if (peek_tk.kind_of? TkLPAREN)
        get_tk
        skip_tkspace
      end
      new_name = get_symbol_or_name
      @scanner.instance_eval{@lex_state = EXPR_FNAME}
      skip_tkspace
      if (peek_tk.kind_of? TkCOMMA)
        get_tk
        skip_tkspace
      end
      old_name = get_symbol_or_name

      al = Alias.new(get_tkread, old_name, new_name, comment)
      al.file = @top_level.file_absolute_name
      al.line = @scanner.reader.content.split("\n")[tk.line_no - 1]
      read_documentation_modifiers(al, ATTR_MODIFIERS)
      if al.document_self
	context.add_alias(al)
      end
    end

    def parse_yield_parameters
      parse_method_or_yield_parameters
    end

  def parse_yield(context, single, tk, method)
    if method.block_params.nil?
      get_tkread
      @scanner.instance_eval{@continue = false}
      method.block_params = parse_yield_parameters
    end
  end

  def parse_require(context, comment)
    skip_tkspace_comment
    tk = get_tk
    if tk.kind_of? TkLPAREN
      skip_tkspace_comment
      tk = get_tk
    end

    name = nil
    case tk
    when TkSTRING
      name = tk.text
#    when TkCONSTANT, TkIDENTIFIER, TkIVAR, TkGVAR
#      name = tk.name
    when TkDSTRING
      warn "Skipping require of dynamic string: #{tk.text}"
 #   else
 #     warn "'require' used as variable"
    end
    if name
      context.add_require(Require.new(name, comment, @top_level.file_absolute_name))
    else
      unget_tk(tk)
    end
  end

  def parse_include(context, comment)
    loop do
      skip_tkspace_comment
      name = get_constant_with_optional_parens
      unless name.empty?
        i = Include.new(name, comment)
        i.file = @top_level.file_absolute_name
        context.add_include(i)
      end
      return unless peek_tk.kind_of?(TkCOMMA)
      get_tk
    end
  end

    def get_bool
      skip_tkspace
      tk = get_tk
      case tk
      when TkTRUE
        true
      when TkFALSE, TkNIL
        false
      else
        unget_tk tk
        true
      end
    end

    def parse_attr(context, single, tk, comment)
      args = parse_symbol_arg(1)
      if args.size > 0
	name = args[0]
        rw = "R"
        skip_tkspace(false)
        tk = get_tk
        if tk.kind_of? TkCOMMA
          rw = "RW" if get_bool
        else
          unget_tk tk
        end
	att = Attr.new(get_tkread, name, rw, comment)
	att.file = @top_level.file_absolute_name
	read_documentation_modifiers(att, ATTR_MODIFIERS)
	if att.document_self
	  context.add_attribute(att)
	end
      else
	warn("'attr' ignored - looks like a variable")
      end    

    end

    def parse_visibility(container, single, tk)
      singleton = (single == SINGLE)
      vis = case tk.name
            when "private"   then :private
            when "protected" then :protected
            when "public"    then :public
            when "private_class_method"
              singleton = true
              :private
            when "public_class_method"
              singleton = true
              :public
            else raise "Invalid visibility: #{tk.name}"
            end
            
      skip_tkspace_comment(false)
      case peek_tk
        # Ryan Davis suggested the extension to ignore modifiers, because he
        # often writes
        #
        #   protected unless $TESTING
        #
      when TkNL, TkUNLESS_MOD, TkIF_MOD
#        error("Missing argument") if singleton        
        container.ongoing_visibility = vis
      else
        args = parse_symbol_arg
        container.set_visibility_for(args, vis, singleton)
      end
    end

    def parse_attr_accessor(context, single, tk, comment)
      args = parse_symbol_arg
      read = get_tkread
      rw = "?"

      # If nodoc is given, don't document any of them

      tmp = CodeObject.new
      read_documentation_modifiers(tmp, ATTR_MODIFIERS)
      return unless tmp.document_self

      case tk.name
      when "attr_reader"   then rw = "R"
      when "attr_writer"   then rw = "W"
      when "attr_accessor" then rw = "RW"
      else
        rw = @options.extra_accessor_flags[tk.name]
      end
      
      for name in args
	att = Attr.new(get_tkread, name, rw, comment)
  	att.file = @top_level.file_absolute_name
        context.add_attribute(att)
      end    
    end

    def skip_tkspace_comment(skip_nl = true)
      loop do
        skip_tkspace(skip_nl)
        return unless peek_tk.kind_of? TkCOMMENT
        get_tk
      end
    end

    def parse_symbol_arg(no = nil)

      args = []
      skip_tkspace_comment
      case tk = get_tk
      when TkLPAREN
	loop do
	  skip_tkspace_comment
	  if tk1 = parse_symbol_in_arg
	    args.push tk1
	    break if no and args.size >= no
	  end
	  
	  skip_tkspace_comment
	  case tk2 = get_tk
	  when TkRPAREN
	    break
	  when TkCOMMA
	  else
           warn("unexpected token: '#{tk2.inspect}'") if $DEBUG
	    break
	  end
	end
      else
	unget_tk tk
	if tk = parse_symbol_in_arg
	  args.push tk
	  return args if no and args.size >= no
	end

	loop do
#	  skip_tkspace_comment(false)
	  skip_tkspace(false)

	  tk1 = get_tk
	  unless tk1.kind_of?(TkCOMMA) 
	    unget_tk tk1
	    break
	  end
	  
	  skip_tkspace_comment
	  if tk = parse_symbol_in_arg
	    args.push tk
	    break if no and args.size >= no
	  end
	end
      end
      args
    end

    def parse_symbol_in_arg
      case tk = get_tk
      when TkSYMBOL
        tk.text.sub(/^:/, '')
      when TkSTRING
	eval @read[-1]
      else
	warn("Expected symbol or string, got #{tk.inspect}") if $DEBUG
	nil
      end
    end
  end

end
