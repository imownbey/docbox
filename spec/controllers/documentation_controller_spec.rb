require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DocumentationController do
  fixtures :all
  it "should get proper objects" do
    CodeContainer.should_receive(:find_by_name).with("SmallClass").and_return(code_containers(:some_class))
    CodeContainer.should_receive(:find_by_name).with("NestedClass").and_return(code_containers(:nested_class))
    
    get :show, :tokens => ["SmallClass", "NestedClass"]
    
    assigns[:objects].should == [code_containers(:some_class), code_containers(:nested_class)]  
  end
end
