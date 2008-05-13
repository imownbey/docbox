require File.dirname(__FILE__) + '/../spec_helper'


describe Comment, "versioning" do
  fixtures :comments, :users, :versions, :code_objects, :containers, :meths
  
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
  
  it "should get the right version" do
    comments(:current).v(2).should == versions(:current_v2)
  end
  
  it "should use current when current versions" do
    comments(:current).v(3).should == comments(:current)
  end
  
  describe 'exporting' do
    it "should not export if previose version has not been exported" do
      versions(:current_v1).update_attributes :exported => false
      lambda {comments(:current).export!(2)}.should raise_error
    end

    it "should change the exported to true" do
      c = comments(:current)
      v1, v2 = versions(:current_v1), versions(:current_v2)
      c.should_receive(:export).with(v1, v2).and_return(true)
      c.export!(2)
      v2.reload
      v2.should be_exported
    end
    
    def mock_file(v1, v2)
      f = mock(File)
      File.should_receive(:open).and_yield(f)
      f.should_receive(:read).and_return(v1)
      f.should_receive(:rewind)
      f.should_receive(:puts).with(v2)
    end

    it "should actually sub out comments" do
      method = <<-EOC
class Foo
  # this is version 1
  def simple_method(foo)
    puts "win"
  end
end
EOC
      replacement = <<-EOC
class Foo
  # this is version two
  def simple_method(foo)
    puts "win"
  end
end
EOC
      mock_file(method, replacement)
      comments(:current).export! 2
    end
    
    it "should keep weird formatting" do
      method = <<-EOC
class Foo
            # this is version 1
        def simple_method(foo)
    puts "win"
  end
end
EOC
      replacement = <<-EOC
class Foo
            # this is version two
        def simple_method(foo)
    puts "win"
  end
end
EOC
      mock_file(method, replacement)
      comments(:current).export! 2
    end
    
    it "should replace propper comment when two are the same" do
      method = <<-EOC
# this is version 1
def not_correct_method
end

# this is version 1
def simple_method(foo)
end
EOC
      replacement = <<-EOC
# this is version 1
def not_correct_method
end

# this is version two
def simple_method(foo)
end
EOC
      mock_file(method, replacement)
      comments(:current).export! 2
    end
    
    it "should work for class too" do
      klass = <<-EOC
# this is not current v1
class Foobar::SmallClass
end
EOC
      replacement = <<-EOC
# This comment is not current
class Foobar::SmallClass
end
EOC
      mock_file(klass, replacement)
      comments(:not_current).export! 2
    end
    
    it "should use propper context" do
      method <<-EOC
class NotTheRightOne
  # this is version 1
  def simple_method(foo)
  end
end

class SmallClass
  end
end
