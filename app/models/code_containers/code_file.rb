class CodeFile < CodeContainer
  has_many :code_containers
  has_many :code_methods
  has_many :code_objects
  
  def type
    "file"
  end
end