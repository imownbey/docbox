require 'mixins'
class CodeMethod < ActiveRecord::Base  
  include TokenParams
  belongs_to :code_container
  has_one :code_comment, :as => :owner, :dependent => :destroy
  belongs_to :code_file
  
  named_scope :ordered, :order => :name
  named_scope :with_comments, :include => [:code_comment]
  
  is_indexed :fields => [:name, :parameters]
  
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
  
  def type
    "method"
  end
end
