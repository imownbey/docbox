require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Change do
  before(:each) do
    @valid_attributes = {
      :type => "value for type",
      :tag_id => "1",
      :owner_id => "1",
      :owner_type => "value for owner_type"
    }
  end

  it "should create a new instance given valid attributes" do
    Change.create!(@valid_attributes)
  end
end
