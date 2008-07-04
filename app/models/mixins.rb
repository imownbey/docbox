module TokenParams
  def path
 method:app/models/mixins.rb
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