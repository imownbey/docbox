require File.dirname(__FILE__) + '/../spec_helper'

describe CodeContainer do
  fixtures :code_containers
  
  it "should get true container" do
    container = code_containers(:colon_class)
    container.true_container.should == code_containers(:some_class)
  end
  
  it "should return self for true container if it is the true container" do
    code_containers(:nested_class).true_container.should == code_containers(:some_class)
  end
end
