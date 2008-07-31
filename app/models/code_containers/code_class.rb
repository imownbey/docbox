require 'mixins'
class CodeClass < CodeContainer
  #include SearchTada
  is_indexed(:fields => [:name],
             :conditions => "type = 'CodeClass'")
             
  def class_type
    "class"
  end
end