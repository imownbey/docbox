require 'duckies'
##
# This is a class comment
class SimpleClass
  module SimpleModule
    # This module has nothing. Sadface
  end
  
  def no_doc
    # This method has no docs
  end
  
  ##
  # This class has a doc
  def docced
    # see?
  end
  
  def params(arg1, arg2)
    # This one takes params
  end
  
  private
  
  def private
    # This method is private
  end
end