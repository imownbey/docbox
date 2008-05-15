require File.dirname(__FILE__) + '/../spec_helper'

describe CodeContainer do
  before(:each) do
    @container = CodeContainer.new
  end

  it "should be valid" do
    @container.should be_valid
  end
end
