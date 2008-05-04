class CodeObject < ActiveRecord::Base
  belongs_to :container
  has_one :comment, :as => :owner, :dependent => :destroy
end

class Alias < CodeObject
  def old_name
    value
  end
  
  def old_name= name
    value = name
  end
end

class Constant < CodeObject
end

class Attribute < CodeObject
end

class Require < CodeObject
end

class Include < CodeObject
end
