module TokenParams
  def path
    path = []
    object = (CodeComment === self ? owner : self)
    while object
      path << "#{object.name}"
      object = object.code_container
      object = nil if object.is_a? CodeFile
    end
    
    path.reverse
  end
end