require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Errors do
  before(:each) do
    @valid_attributes = {
      :pre_version_id => "1",
      :version_id => "1",
      :type => "value for type",
      :message => "value for message"
    }
  end

  it "should create a new instance given valid attributes" do
    Errors.create!(@valid_attributes)
  end
end
