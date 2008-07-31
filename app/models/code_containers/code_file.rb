class CodeFile < CodeContainer
  has_many :code_containers
  has_many :code_methods
  has_many :code_objects
  
  def class_type
    "file"
  end
  
  def code_file
    self
  end
end