require 'digest/md5' # This is to find comments which are the same

# Sub in our own parse_rb and code_objects
require 'rdoc/parse_rb'
require 'rdoc/code_objects'

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
    def initialize(options) #:not-new:
      @options = options
      @previous_comments = CodeComment.all.collect(&:id)
      @previous_containers = CodeContainer.all.collect(&:id)
      @previous_methods = CodeMethod.all.collect(&:id)
      @previous_objects = CodeObject.all.collect(&:id)
      @previous_in_files = InFile.all.collect(&:id)
      
      # set up a hash to keep track of all the classes/modules we have processed
      @already_processed = {}
      
      # Set up to look for first comment md5
      
      # set up a hash to keep track of all of the objects to be output
      @output = {:files => [], :classes => [], :modules => [], :attributes => [],
        :methods => [], :aliases => [], :constants => [], :requires => [], :includes => []}
      
      # sequences used to generate unique ids for inserts
      @seq = {:code_containers => 0, :methods => 0, :code_objects => 0}
    end
                 
    # Rdoc passes in TopLevel objects from the code_objects.rb tree (all files)
    def generate(files)                             
      # Each object passed in is a file, process it
      @comments = []
      @containers = []
      @objects = []
      @methods = []
      @in_files = []
      
      files.each { |file| add_file(file) }
      
      files.each { |file| process_file(file) }
      
      files.each { |file| process_in_files(file) }
      
      (@previous_comments   - @comments).each   {|id| CodeComment.find(id).destroy   }
      (@previous_objects    - @objects).each    {|id| CodeObject.find(id).destroy    }
      (@previous_methods    - @methods).each    {|id| CodeMethod.find(id).destroy    }
      (@previous_containers - @containers).each {|id| CodeContainer.find(id).destroy }
      (@previous_in_files   - @in_files).each   {|id| InFile.find(id).destroy        }
    end

    private
    
    def process_in_files(parent)
      parent.each_classmodule do |child| 
        begin
        ar_container = CodeContainer.find_by_full_name(child.full_name)
        child.in_files.each do |in_file|
          in_file_file = CodeFile.find_by_full_name(in_file.file_absolute_name)
          f = InFile.create_or_update_by_code_container_id_and_code_file_id({
            :code_container_id => ar_container.id, 
            :code_file_id => in_file_file.id})
          @in_files << f.id
        end
        rescue
          # If it errors we just skip it.This shit isn't that important.
        end
        # Recursivly do this shit
        process_in_files(child)
      end
    end

    # process a file from the code_object.rb tree
    def add_file(file)
      @first_comment = false
 
      d = CodeFile.create :name => file.file_relative_name, :full_name => file.file_absolute_name
 
      @containers << d.id
      # TODO: For some reason this is not being reset. WTF. But yet CodeFiles are being created.
      @current_file = d
      
 
  #   # Process all of the objects that this file contains
  #   file.method_list.each { |child| process_method(child, file) }
  #   file.aliases.each { |child| process_alias(child, file) }
  #   file.constants.each { |child| process_constant(child, file) }
  #   file.requires.each { |child| process_require(child, file) }
  #   file.includes.each { |child| process_include(child, file) }
  #   file.attributes.each { |child| process_attribute(child, file) }
  #   
  #   # Recursively process contained subclasses and modules
  #   
  #   @file = file
  #   file.each_classmodule do |child|
  #     process_type_or_module(child, file)
  #   end
      
      comment = CodeComment.create_or_update_by_owner_id_and_owner_type_and_owner_type :exported_body => file.comment, :owner_id => d.id, :owner_type => d.class unless file.comment.blank? || Digest::MD5.hexdigest(file.comment) == @first_comment
        @comments << comment.id if comment
      @current_file = nil
    end
    
    def process_file(file)
     # # Process all of the objects that this file contains
     # file.method_list.each { |child| process_method(child, file) }
     # file.aliases.each { |child| process_alias(child, file) }
     # file.constants.each { |child| process_constant(child, file) }
     # file.requires.each { |child| process_require(child, file) }
     # file.includes.each { |child| process_include(child, file) }
     # file.attributes.each { |child| process_attribute(child, file) }
     # 
     # # Recursively process contained subclasses and modules
      
      file.each_classmodule do |child|
        process_type_or_module(child, file)
      end    
    end  
    
    # Process classes and modiles   
    def process_type_or_module(obj, parent)
      @first_comment ||= Digest::MD5.hexdigest(obj.comment) if obj.comment
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
        parent = CodeContainer.find_by_name(parent.name) || CodeContainer.find_by_name(parent.file_relative_name)
        p = case type
            when :modules
            
              CodeModule.create_or_update_by_full_name_and_code_container_id(:code_file_id => CodeFile.find_by_full_name(obj.file).try(:id), :code_container_id => parent.id, :name => obj.name, :full_name => obj.full_name, :superclass => obj.superclass, :line_code => obj.line)
            when :classes
              CodeClass.create_or_update_by_full_name_and_code_container_id(:code_file_id => CodeFile.find_by_full_name(obj.file).try(:id), :code_container_id => parent.id, :name => obj.name, :full_name => obj.full_name, :superclass => obj.superclass, :line_code => obj.line)
            end
        comment = CodeComment.create_or_update_by_owner_id_and_owner_type :exported_body => obj.comment, :owner_id => p.id, :owner_type => p.class unless obj.comment.blank?
        @containers << p.id
        @comments << comment.id if comment
        @current_container = p
        @already_processed[obj.full_name] = true    
          
        # Process all of the objects that this class or module contains
      obj.method_list.each { |child| process_method(child, p) unless child.nil? }
      obj.aliases.each { |child| process_alias(child, p) }
      obj.constants.each { |child| process_constant(child, p) }
      obj.requires.each { |child| process_require(child, p) }
      obj.includes.each { |child| process_include(child, p) }
      obj.attributes.each { |child| process_attribute(child, p) }   
      end
      
      id = @already_processed[obj.full_name]
      # Recursively process contained subclasses and modules 
      obj.each_classmodule do |child| 
      	process_type_or_module(child, obj) 
      end
      
    end       
    
    def process_method(obj, parent)
      if obj.is_alias_for.nil?
        @first_comment ||= Digest::MD5.hexdigest(obj.comment) if obj.comment
        $stderr.puts "Could not find parent object for #{obj.name}" unless parent = CodeContainer.find_by_name(parent.name)
        p = CodeMethod.create(:code_file_id => CodeFile.find_by_full_name(obj.file).try(:id), :code_container_id => @current_container.id, :name => obj.name, :parameters => obj.params, :block_parameters => obj.block_params, :singleton => obj.singleton, :visibility => obj.visibility.to_s, :force_documentation => obj.force_documentation, :source_code => get_source_code(obj))
        comment = CodeComment.create_or_update_by_owner_id_and_owner_type :exported_body => obj.comment, :owner_id => p.id, :owner_type => p.class unless obj.comment.blank?
        @methods << p.id
        @comments << comment.id if comment
      else
        process_alias(obj, parent, true)
      end
    end
    
    def process_alias(obj, parent, from_method = false)
      @first_comment ||= Digest::MD5.hexdigest(obj.comment) if obj.comment
      parent = CodeContainer.find_by_name(parent.name)
      if from_method
        p = CodeAlias.create({
          :code_file_id => CodeFile.find_by_full_name(obj.file).try(:id), 
          :code_container_id => parent.try(:id), 
          :name => obj.name, 
          :old_name => obj.is_alias_for.name,
        })
      else
        p = CodeAlias.create({
          :code_file_id => CodeFile.find_by_full_name(obj.file).try(:id), 
          :code_container_id => parent.try(:id), 
          :name => (obj.try(:new_name) || obj.name), 
          :old_name => (obj.try(:old_name) || obj.is_alias_for.name),
        })
      end
      @objects << p.id
    end
    
    def process_constant(obj, parent)
      @first_comment ||= Digest::MD5.hexdigest(obj.comment) if obj.comment
      parent = CodeContainer.find_by_name(parent.name)
      p = CodeConstant.create_or_update_by_name_and_code_container_id(:code_file_id => CodeFile.find_by_full_name(obj.file).try(:id), :code_container_id => parent.try(:id), :name => obj.name, :value => obj.value)
      comment = CodeComment.create_or_update_by_owner_id_and_owner_type :exported_body => obj.comment, :owner_id => p.id, :owner_type => p.class unless obj.comment.blank?
      @objects << p.id
      @comments << comment.id if comment
    end
    
    def process_attribute(obj, parent)
      @first_comment ||= Digest::MD5.hexdigest(obj.comment) if obj.comment
      parent = CodeContainer.find_by_name(parent.name)
      p = CodeAttribute.create_or_update_by_name_and_code_container_id(:code_file_id => CodeFile.find_by_full_name(obj.file).try(:id), :code_container_id => parent.try(:id), :name => obj.name, :read_write => obj.rw)
      comment = CodeComment.create_or_update_by_owner_id_and_owner_type :exported_body => obj.comment, :owner_id => p.id, :owner_type => p.class unless obj.comment.blank?
      @objects << p.id
      @comments << comment.id if comment
    end
    
    def process_require(obj, parent)
      @first_comment ||= Digest::MD5.hexdigest(obj.comment) if obj.comment
      parent = CodeContainer.find_by_name(parent.name)
      p = CodeRequire.create_or_update_by_name_and_code_container_id(:code_file_id => CodeFile.find_by_full_name(obj.file), :code_container_id => parent.try(:id), :name => obj.name)
      comment = CodeComment.create_or_update_by_owner_id_and_owner_type :exported_body => obj.comment, :owner_id => p.id, :owner_type => p.class unless obj.comment.blank?
      @objects << p.id
      @comments << comment.id if comment
    end
    
    def process_include(obj, parent)
      @first_comment ||= Digest::MD5.hexdigest(obj.comment) if obj.comment
      parent = CodeContainer.find_by_name(parent.name)
      p = CodeInclude.create_or_update_by_name_and_code_container_id(:code_file_id => CodeFile.find_by_full_name(obj.file).try(:id), :code_container_id => parent.try(:id), :name => obj.name)
      comment = CodeComment.create_or_update_by_owner_id_and_owner_type :exported_body => obj.comment, :owner_id => p.id, :owner_type => p.class unless obj.comment.blank?
      @objects << p.id
      @comments << comment.id if comment
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
    attr_accessor :id, :code_container_id
  end 

  # dynamically add a source code attribute to the base oject of code_objects.rb
  class RDoc::AnyMethod
    attr_accessor :source_code	  
  end
end # module Generators