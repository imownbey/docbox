require File.dirname(__FILE__) + '/../spec_helper'

describe Comment, "versioning" do
  it "should create a new version when saved" do
    lambda {
      c = comments(:default)
      c.update_attributes :body => 'This is a newer comment'
    }.should change(Version, :count).by(1)
  end
end
