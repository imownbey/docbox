module TokenParams
  def to_path
    path = []
    object = (CodeComment === self ? owner : self)
    while object
      path << "#{object.name}"
      object = object.code_container
      object = nil if object.is_a? CodeFile
    end
    
    path.reverse
  end
  
  def fully_qualified_name
    path = to_path
    
    if self.class == CodeMethod
      method_name = path.pop
      (path.join("::")) + "##{method_name}"
    else
      path.join("::")
    end
  end
end