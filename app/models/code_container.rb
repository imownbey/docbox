require 'mixins'
class CodeContainer < ActiveRecord::Base
  include TokenParams
  include Documentable
  
  has_many :code_objects
  has_many :code_constants
  has_many :code_attributes
  has_many :code_methods
  has_many :code_containers
  belongs_to :code_container
  
  has_many :in_files
  has_many :code_files, :through => :in_files
  
  named_scope :not_file, :conditions => ["type != 'CodeFile'"]
  named_scope :main_comment, :conditions => {:main_comment => true}
  
  def short_name
    self.full_name.split("::").pop
  end
    
  def true_container
    if code_container.is_a? CodeFile
      return code_container
    end
    
    if line_code && match = line_code.match(/\s*class\s+([^#:]*)(::)/) # This finds if there are :: in the line_code and gets the first one
      initial_class = match[1]
      if container = CodeContainer.find_by_name(initial_class)
        return container.code_container
      else
        return false
      end
    else
      return code_container
    end
  end
end