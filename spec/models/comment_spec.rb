require File.dirname(__FILE__) + '/../spec_helper'


describe Comment, "versioning" do
  fixtures :comments, :users
  
  before(:each) do
    login_as :aaron
  end
  
  it "should create a new version when saved" do
    lambda {
      c = comments(:not_current)
      c.update_attributes :body => 'This is a newer comment'
    }.should change(Version, :count).by(1)
  end
end
