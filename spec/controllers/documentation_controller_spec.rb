require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DocumentationController do
  fixtures :all
  it "should get proper objects" do
    CodeContainer.should_receive(:find_by_name).with("SmallClass").and_return(code_containers(:some_class))
    CodeContainer.should_receive(:find_by_name).with("NestedClass").and_return(code_containers(:nested_class))
    
    get :show, :tokens => ["SmallClass", "NestedClass"]
    
    assigns[:objects].should == [code_containers(:some_class), code_containers(:nested_class)]  
  end

  it "should get file for /files/" do
    file = code_containers(:file)
    comment = code_comments(:file_comment)
    CodeFile.should_receive(:find_by_full_name).with("path/to/somefile.rb").and_return(file)
    file.should_receive(:comment).and_return(comment)
    
    get :show_file, :path => %W{path to somefile.rb}
    assigns[:file].should == file
    assigns[:comment].should == comment
  end
end
