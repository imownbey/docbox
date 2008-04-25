require 'erb'

# Heavely taken from http://rannotate.rubyforge.org/

# This class processes the results of the rdoc parsing and outputs sql INSERT 
# statements into a file called inserts.sql
#
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
  class SqlGenerator                 

    TYPE = {:file => 1, :class => 2, :module => 3 }
    VISIBILITY = {:public => 1, :private => 2, :protected => 3 }
        
    # Create a new Sql Generator object (used by RDoc)
    def SqlGenerator.for(options)
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
      @seq = 0            
    end

    # Rdoc passes in TopLevel objects from the code_objects.rb tree (all files)
    def generate(files)                             
      # before doing anything make sure we can output
      @rhtml = ERB.new(load_template())          
      f = File.new("inserts.sql", File::CREAT|File::TRUNC|File::RDWR)
      f.close       
    
      # Each object passed in is a file, process it
      files.each { |file| process_file(file) }
     
      f = File.new("inserts.sql", File::CREAT|File::TRUNC|File::RDWR)      
      f << @rhtml.result(binding)
      f.close      
    end

    private

    # process a file from the code_object.rb tree
    def process_file(file)
      id = get_next_id(:files)
      @output[:files].push(add_object(file, id, 0))
          
      # Process all of the objects that this file contains
      file.method_list.each { |child| process_method(child, file, id) }
      file.aliases.each { |child| process_alias(child, file, id) }
      file.constants.each { |child| process_constant(child, file, id) }
      file.requires.each { |child| process_require(child, file, id) }
      file.includes.each { |child| process_include(child, file, id) }
      file.attributes.each { |child| process_attribute(child, file, id) }   
    
      # Recursively process contained subclasses and modules 
       file.each_classmodule do |child| 
          process_class_or_module(child, file, id)      
      end   
    end
    
    # Process classes and modiles   
    def process_class_or_module(obj, parent, parent_id)
      obj.is_module? ? type = :modules : type = :classes
    
      # One important note about the code_objects.rb structure. A class or module
      # definition can be spread a cross many files in Ruby so code_objects.rb handles
      # this by keeping only *one* reference to each class or module that has a definition
      # at the root level of a file (ie. not contained in another class or module).
      # This means that when we are processing files we may run into the same class/module
      # twice. So we need to keep track of what classes/modules we have
      # already seen and make sure we don't create two INSERT statements for the same
      # object.
      if(!@already_processed.has_key?(obj.full_name)) then      
        id = get_next_id(type)
        @output[type].push(add_object(obj, id, parent_id))
        @already_processed[obj.full_name] = id        
          
        # Process all of the objects that this class or module contains
        obj.method_list.each { |child| process_method(child, obj, id) }
        obj.aliases.each { |child| process_alias(child, obj, id) }
        obj.constants.each { |child| process_constant(child, obj, id) }
        obj.requires.each { |child| process_require(child, obj, id) }
        obj.includes.each { |child| process_include(child, obj, id) }
        obj.attributes.each { |child| process_attribute(child, obj, id) }   
      end
      
      id = @already_processed[obj.full_name]
      # Recursively process contained subclasses and modules 
      obj.each_classmodule do |child| 
      	process_class_or_module(child, obj, id) 
      end
    end       
    
    def process_method(obj, parent, parent_id)  
      id = get_next_id(:methods)  
      
      obj.source_code = get_source_code(obj)
      
      @output[:methods].push(add_object(obj, id, parent_id))                                
    end
    
    def process_alias(obj, parent, parent_id)
      id = get_next_id(:aliases)    
      @output[:aliases].push(add_object(obj, id, parent_id))  
    end
    
    def process_constant(obj, parent, parent_id)
      id = get_next_id(:constants)    
      @output[:constants].push(add_object(obj, id, parent_id))    
    end
    
    def process_attribute(obj, parent, parent_id)
      id = get_next_id(:attributes)   
      @output[:attributes].push(add_object(obj, id, parent_id))     
    end
    
    def process_require(obj, parent, parent_id)
      id = get_next_id(:requires)
      @output[:requires].push(add_object(obj, id, parent_id)) 
    end
    
    def process_include(obj, parent, parent_id) 
      id = get_next_id(:includes)   
      @output[:includes].push(add_object(obj, id, parent_id))     
    end   
    
    # load the RHTML template
    def load_template   
      p Dir.getwd
      return File.read('rdoc.sql.rb')
    end
    
    # required so that ERb can access the bindings of this object
    def get_binding
    	binding
    end
    
 	def escape_sql(str)  
 	  if(str == nil) then return '' end
 	
 	  str.gsub(/([\0\n\r\032\'\"\\])/) do
        case $1
          when "\0" then "\\0"
          when "\n" then "\\n"
          when "\r" then "\\r"
          when "\032" then "\\Z"
          else "\\"+$1
        end
      end
    end    
                
    # Set the id and container ID of this object
    def add_object(obj, id, container_id)
      obj.id = id
      obj.container_id = container_id
      return obj
    end

	# get the next unique ID      
    def get_next_id(name = nil)
      @seq = @seq + 1
      return @seq
    end                 
    
    # Transform true/false -> 1/0
    def bool_to_int(bool_val)
      if(bool_val == nil)
        return 0
      end
      return bool_val ? 1 : 0
    end
    
    # get the source code
    def get_source_code(method)
      src = ""
	  if(ts = method.token_stream)    
	    ts.each do |t|
	    next unless t    			
	      src << t.text
	    end
      end
      return src
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

end