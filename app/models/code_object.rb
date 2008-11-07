require 'mixins'
class CodeObject < ActiveRecord::Base
  include TokenParams
  include Documentable
  
  belongs_to :code_container
  
  def true_container
    code_container
  end
  
  def full_name
    self.name
  end
end