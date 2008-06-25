require 'mixins'
class CodeMethod < ActiveRecord::Base
  include TokenParams
  belongs_to :code_container
  has_one :code_comment, :as => :owner, :dependent => :destroy
  
  def true_container
    code_container
  end
end
