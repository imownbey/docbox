require File.dirname(__FILE__) + '/../spec_helper'
describe CodeObject do
  fixtures :code_objects, :code_containers
  
  it "should get true container" do
    code_objects(:require).true_container.should == code_containers(:some_class)
  end
end
