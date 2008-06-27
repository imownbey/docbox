require 'mixins'
class CodeMethod < ActiveRecord::Base
  include TokenParams
  belongs_to :code_container
  has_one :code_comment, :as => :owner, :dependent => :destroy
  
  named_scope :ordered, :order => :name
  
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
end
