require File.dirname(__FILE__) + '/../spec_helper'

describe CodeContainer do
  fixtures :code_containers
  
  it "should handle a class hierarchy" do
    container = code_containers(:colon_class)
    
    container.path.should == ["SmallClass", "NestedClass", "ColonClass"] 
  end
  
  it "should handle a top level class" do
    container = code_containers(:some_class)
    
    container.path.should == ["SmallClass"] 
  end
end