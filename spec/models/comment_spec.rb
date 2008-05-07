require File.dirname(__FILE__) + '/../spec_helper'


describe Comment, "versioning" do
  fixtures :comments, :users
  
  it "should create a new version when saved" do
    lambda {
      c = comments(:not_current)
      c.update_attributes :body => 'This is a newer comment'
    }.should change(Version, :count).by(1)
  end
  
  it "should move current" do
    c = comments(:current)
    c.update_attributes :body => 'New comment'
    c.should_not be_exported
    c.versions.last.should be_exported
  end
  
  it "should move body" do
    c = comments(:current)
    old_body = c.body
    c.update_attributes :body => 'New Comment!'
    c.versions.last.body.should == old_body
  end
  
  it "should move user" do
    c = comments(:current)
    c.update_attributes :body => 'New Body!', :user => users(:quentin)
    c.versions.last.user.should == users(:aaron)
    c.user.should == users(:quentin)
  end
  
  it "should up version number when edited" do
    c = comments(:current)
    old_v = c.version
    c.update_attributes :body => 'New Body!', :user => users(:quentin)
    c.version.should == old_v + 1
  end
end
