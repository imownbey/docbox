class CodeAlias < CodeObject
  def old_name
    value
  end
  
  def old_name= name
    self.value = name
  end
end