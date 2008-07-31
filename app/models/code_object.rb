require 'mixins'
class CodeObject < ActiveRecord::Base
  include TokenParams
  belongs_to :code_container
  has_one :code_comment, :as => :owner, :dependent => :destroy
  has_one :code_file
  
  def true_container
    code_container
  end
  
  def full_name
    self.name
  end
end