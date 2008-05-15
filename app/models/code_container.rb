class CodeContainer < ActiveRecord::Base
  has_many :code_objects
  has_many :code_methods
  belongs_to :code_container
  has_one :code_comment, :as => :owner, :dependent => :destroy
end

class CodeClass < CodeContainer
end

class CodeModule < CodeContainer
end

class CodeFile < CodeContainer
end