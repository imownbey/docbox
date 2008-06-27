require 'mixins'
class CodeContainer < ActiveRecord::Base
  include TokenParams
  has_many :code_objects
  has_many :code_methods
  has_many :code_containers
  belongs_to :code_container
  has_one :code_comment, :as => :owner, :dependent => :destroy
  
  named_scope :not_file, :conditions => ["type != 'CodeFile'"]
  
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

class CodeClass < CodeContainer
end

class CodeModule < CodeContainer
end

class CodeFile < CodeContainer
end