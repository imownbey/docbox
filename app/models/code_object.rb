class CodeObject < ActiveRecord::Base
  belongs_to :code_container
  has_one :code_comment, :as => :owner, :dependent => :destroy
  
  def true_container
    code_container
  end
end

class CodeAlias < CodeObject
  def old_name
    value
  end
  
  def old_name= name
    value = name
  end
end

class CodeConstant < CodeObject
end

class CodeAttribute < CodeObject
end

class CodeRequire < CodeObject
end

class CodeInclude < CodeObject
end
