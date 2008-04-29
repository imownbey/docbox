require File.dirname(__FILE__) + '/../spec_helper'

describe CodeObject do
  before(:each) do
    @code_object = CodeObject.new
  end

  it "should be valid" do
    @code_object.should be_valid
  end
end
