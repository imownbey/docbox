require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationHelper do
  fixtures :all
  it "should generate proper path with tokens_path" do
    klass = code_containers(:nested_class)
    tokens_path(klass).should == "SmallClass/NestedClass"
  end

end
