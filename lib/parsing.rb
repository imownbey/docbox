# This is a UGLY hack.
# It lets me keep track of the line that classes are on
# And makes things generally easier
CLASSES = {}
MODULES = {}
module RDoc
  class RDoc
    def import!(argv)
      TopLevel::reset

      @stats = Stats.new

      options = Options.instance
      options.parse(argv, GENERATORS)

      @last_created = nil
      start_time = Time.now

      file_info = parse_files(options)

      if file_info.empty?
        return false
      else
        $stderr.puts "\nParsing Documentation..."
        gen = Generators::Importer.new(options)
        gen.generate(file_info)
      end
    end
  end
  
  class RubyParser
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
          MODULES[name] = name_t.line_no
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
          CLASSES[name] = name_t.line_no
    end
  end
end
# This class takes RDoc and inputs it into the models using RDocs generator support

# How does it work?
# Rdoc calls the generate method of this class from inside of rdoc.rb. By the 
# time rdoc calls the generate method it has parsed all of the source files 
# and has put them in a tree structure. The details of this tree structure 
# are in the file code_objects.rb. 
#
# generate gets passed an array of 'toplevel' objects which are files
# we process these toplevel objects recursivley extracting all of the code 
# objects they contain: classes, modules, methods, attributes etc..
module Generators
  # This generator takes the output of the rdoc parser
  # and turns it into a bunch of INSERT sql statements for a database
  class Importer               

    TYPE = {:file => 1, :class => 2, :module => 3 }
        
    # Create a new Sql Generator object (used by RDoc)
    def self.for(options)
      new(options)
    end
        
    # Greate a new generator and open up the file that will contain all the INSERT statements
    def initialize(options) #:not-new:
      @options = options
      
      # set up a hash to keep track of all the classes/modules we have processed
      @already_processed = {}
      
      # set up a hash to keep track of all of the objects to be output
      @output = {:files => [], :classes => [], :modules => [], :attributes => [], 
        :methods => [], :aliases => [], :constants => [], :requires => [], :includes => []}   
      
      # sequences used to generate unique ids for inserts
      @seq = {:containers => 0, :methods => 0, :code_objects => 0}
    end

    # Rdoc passes in TopLevel objects from the code_objects.rb tree (all files)
    def generate(files)                             
      # Each object passed in is a file, process it
      files.each { |file| process_file(file) }
    end

    private

    # process a file from the code_object.rb tree
    def process_file(file)
      d = Doc.create :name => file.file_relative_name, :full_name => file.file_absolute_name
      Comment.create :body => file.comment, :owner => d unless file.comment.blank?
      # Process all of the objects that this file contains
      file.method_list.each { |child| process_method(child, file) }
      file.aliases.each { |child| process_alias(child, file) }
      file.constants.each { |child| process_constant(child, file) }
      file.requires.each { |child| process_require(child, file) }
      file.includes.each { |child| process_include(child, file) }
      file.attributes.each { |child| process_attribute(child, file) }   
    
      # Recursively process contained subclasses and modules 
      file.each_classmodule do |child| 
        process_class_or_module(child, file)      
      end   
    end
    
    # Process classes and modiles   
    def process_class_or_module(obj, parent)
      type = obj.is_module? ? :modules : :classes
      # One important note about the code_objects.rb structure. A class or module
      # definition can be spread a cross many files in Ruby so code_objects.rb handles
      # this by keeping only *one* reference to each class or module that has a definition
      # at the root level of a file (ie. not contained in another class or module).
      # This means that when we are processing files we may run into the same class/module
      # twice. So we need to keep track of what classes/modules we have
      # already seen and make sure we don't create two INSERT statements for the same
      # object.
      if(!@already_processed.has_key?(obj.full_name)) then    
        parent = Container.find_by_name(parent.name) || Container.find_by_name(parent.file_relative_name)
        p = case type
            when :modules
              Mod.create(:parent => parent, :name => obj.name, :full_name => obj.full_name, :superclass => obj.superclass, :line_no => MODULES[obj.name])
            when :classes
              Klass.create(:parent => parent, :name => obj.name, :full_name => obj.full_name, :superclass => obj.superclass, :line_no => CLASSES[obj.name])
            end
        Comment.create :body => obj.comment, :owner => p unless obj.comment.blank?

        @already_processed[obj.full_name] = true    
          
        # Process all of the objects that this class or module contains
        obj.method_list.each { |child| process_method(child, obj) }
        obj.aliases.each { |child| process_alias(child, obj) }
        obj.constants.each { |child| process_constant(child, obj) }
        obj.requires.each { |child| process_require(child, obj) }
        obj.includes.each { |child| process_include(child, obj) }
        obj.attributes.each { |child| process_attribute(child, obj) }   
      end
      
      id = @already_processed[obj.full_name]
      # Recursively process contained subclasses and modules 
      obj.each_classmodule do |child| 
      	process_class_or_module(child, obj) 
      end
    end       
    
    def process_method(obj, parent)
      $stderr.puts "Could not find parent object for #{obj.name}" unless parent = Container.find_by_name(parent.name)
      p = Meth.create(:container => parent, :name => obj.name, :parameters => obj.params, :block_parameters => obj.block_params, :singleton => obj.singleton, :visibility => obj.visibility.to_s, :force_documentation => obj.force_documentation, :source_code => get_source_code(obj))
      Comment.create :body => obj.comment, :owner => p unless obj.comment.blank?
    end
    
    def process_alias(obj, parent)
      $stderr.puts "Could not find parent object for #{obj.name}" unless parent = Container.find_by_name(parent.name)
      p = Alias.create(:container => parent, :name => obj.name, :old_name => obj.new_name)
      Comment.create :body => obj.comment, :owner => p unless obj.comment.blank?
    end
    
    def process_constant(obj, parent)
      $stderr.puts "Could not find parent object for #{obj.name}" unless parent = Container.find_by_name(parent.name)
      p = Constant.create(:container => parent, :name => obj.name, :value => obj.value)
      Comment.create :body => obj.comment, :owner => p unless obj.comment.blank?
    end
    
    def process_attribute(obj, parent)
      $stderr.puts "Could not find parent object for #{obj.name}" unless parent = Container.find_by_name(parent.name)
      p = Attribute.create(:container => parent, :name => obj.name, :read_write => obj.rw)
      Comment.create :body => obj.comment, :owner => p unless obj.comment.blank?
    end
    
    def process_require(obj, parent)
      $stderr.puts "Could not find parent object for #{obj.name}" unless parent = Container.find_by_name(parent.name)
      p = Require.create(:container => parent, :name => obj.name)
      Comment.create :body => obj.comment, :owner => p unless obj.comment.blank?
    end
    
    def process_include(obj, parent) 
      $stderr.puts "Could not find parent object for #{obj.name}" unless parent = Container.find_by_name(parent.name)
      p = Include.create(:container => parent, :name => obj.name)
      Comment.create :body => obj.comment, :owner => p unless obj.comment.blank?
    end
    
    # get the source code
    def get_source_code(method)
      src = ""
  	  if ts = method.token_stream 
  	    ts.each do |t|
  	      next unless t    			
    	    src << t.text
    	  end
      end
      return src
    end   
     
  end # class SqlGenerator

  class RDoc::ClassModule
    if @parent && @parent.full_name
      @parent.name + "::" + @name
    else
      @name
    end
  end
  # dynamically add the id/container_id to the base object of code_objects.rb
  class RDoc::CodeObject
    attr_accessor :id, :container_id
  end 

  # dynamically add a source code attribute to the base oject of code_objects.rb
  class RDoc::AnyMethod
    attr_accessor :source_code	  
  end
end # module Generators