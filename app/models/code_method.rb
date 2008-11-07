require 'mixins'
class CodeMethod < ActiveRecord::Base  
  include TokenParams
  include Documentable
  
  belongs_to :code_container
  
  
  named_scope :ordered, :order => :name
  named_scope :with_comments, :include => [:code_comment]
  named_scope :with_container, :include => [:code_container]
    
  def full_name
    "#{self.name} #{self.parameters}"
  end
  
  def true_container
    code_container
  end
  
  def public?
    self.visibility == 'public'
  end
  
  def private?
    self.visibility == 'private'
  end
  
  def protected?
    self.visibility == 'protected'
  end
  
  def class_type
    "method"
  end
end
