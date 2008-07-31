class CodeModule < CodeContainer
  is_indexed(:fields => [:name], 
             :conditions => "type = 'CodeModule'")
  
  def class_type
    "module"
  end
end