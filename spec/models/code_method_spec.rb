require File.dirname(__FILE__) + '/../spec_helper'
describe CodeObject do
  fixtures :code_methods, :code_containers
  
  it "should get true container as self" do
    code_methods(:simple_method).true_container.should == code_containers(:some_class)
  end
end
