require File.dirname(__FILE__) + '/../spec_helper'

describe Version do
  before(:each) do
    @version = Version.new
  end

  it "should be valid" do
    @version.should be_valid
  end
end
