require File.dirname(__FILE__) + '/../spec_helper'


describe CodeComment, "versioning" do
  fixtures :code_comments, :users, :versions, :code_objects, :code_containers, :code_methods
  
  it "should create a new version when saved" do
    lambda {
      c = code_comments(:not_current)
      c.update_attributes :body => 'This is a newer comment'
    }.should change(Version, :count).by(1)
  end
  
  it "should move current" do
    c = code_comments(:current)
    c.update_attributes :body => 'New comment'
    c.should_not be_exported
    c.versions.last.should be_exported
  end
  
  it "should move body" do
    c = code_comments(:current)
    old_body = c.body
    c.update_attributes :body => 'New Comment!'
    c.versions.last.body.should == old_body
  end
  
  it "should move user" do
    c = code_comments(:current)
    c.update_attributes :body => 'New Body!', :user => users(:quentin)
    c.versions.last.user.should == users(:aaron)
    c.user.should == users(:quentin)
  end
  
  it "should up version number when edited" do
    c = code_comments(:current)
    old_v = c.version
    c.update_attributes :body => 'New Body!', :user => users(:quentin)
    c.version.should == old_v + 1
  end
  
  it "should get the right version" do
    code_comments(:current).v(2).should == versions(:current_v2)
  end
  
  it "should use current when current versions" do
    code_comments(:current).v(3).should == code_comments(:current)
  end
  
  describe 'exporting' do
    it "should not export if previose version has not been exported" do
      versions(:current_v1).update_attributes :exported => false
      lambda {code_comments(:current).export!(2)}.should raise_error
    end

    it "should change the exported to true" do
      c = code_comments(:current)
      v1, v2 = versions(:current_v1), versions(:current_v2)
      c.should_receive(:export).with(v1, v2).and_return(true)
      c.export!(2)
      v2.reload
      v2.should be_exported
    end
    
    def mock_file(v1, v2)
      File.should_receive(:new).and_return(v1)
      v1.should_receive(:read).any_number_of_times.and_return(v1)
      v1.should_receive(:rewind)
      v1.should_receive(:puts).with(v2)
      v1.should_receive(:close)
    end

    it "should actually sub out comments" do
      method = <<-EOC
class SmallClass
  # this is version 1
  def simple_method(foo)
    puts "win"
  end
end
EOC
      replacement = <<-EOC
class SmallClass
  # this is version two
  def simple_method(foo)
    puts "win"
  end
end
EOC
      mock_file(method, replacement)
      code_comments(:current).export! 2
    end
    
    it "should keep weird formatting" do
      method = <<-EOC
class SmallClass
            # this is version 1
        def simple_method(foo)
    puts "win"
  end
end
EOC
      replacement = <<-EOC
class SmallClass
            # this is version two
        def simple_method(foo)
    puts "win"
  end
end
EOC
      mock_file(method, replacement)
      code_comments(:current).export! 2
    end
    
    it "should replace propper comment when two are the same" do
      code_comments(:current).owner.code_container = nil
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
      code_comments(:current).export! 2
    end
    
    it "should work for class too" do
      klass = <<-EOC
# this is not current v1
class SmallClass
end
EOC
      replacement = <<-EOC
# This comment is not current
class SmallClass
end
EOC
      mock_file(klass, replacement)
      code_comments(:not_current).export! 2
    end
    
    it "should use propper context" do
      method = <<-EOC
class NotTheRightOne
  # this is version 1
  def simple_method(foo)
  end
end

class SmallClass
  # this is version 1
  def simple_method(foo)
  end
end
EOC

      replacement = <<-EOC
class NotTheRightOne
  # this is version 1
  def simple_method(foo)
  end
end

class SmallClass
  # this is version two
  def simple_method(foo)
  end
end
EOC
      mock_file(method, replacement)
      code_comments(:current).export! 2
    end
    
    it "should use context for classes" do
      klass = <<-EOC
class OtherClass
  # this is a old comment of a nested class
  class NestedClass
  end
end

class SmallClass
  # this is a old comment of a nested class
  class NestedClass
  end
end
EOC
      replacement = <<-EOC
class OtherClass
  # this is a old comment of a nested class
  class NestedClass
  end
end

class SmallClass
  # This is the comment of a nested class
  class NestedClass
  end
end
EOC
      mock_file(klass, replacement)
      code_comments(:nested_class).export! 2
    end
    
    it "should use context for :: classes" do
      klass = <<-EOC
class OtherClass
  # this class has an old colon
  class NestedClass::ColonClass
  end
end

class SmallClass
  # this class has an old colon
  class NestedClass::ColonClass
  end
end
EOC

      replacement = <<-EOC
class OtherClass
  # this class has an old colon
  class NestedClass::ColonClass
  end
end

class SmallClass
  # this class has a colon
  class NestedClass::ColonClass
  end
end
EOC
      mock_file(klass, replacement)
      code_comments(:colon_class).export! 2
    end
    
    it "should work when no previous comment is there" do
      method = <<-EOC
class SmallClass
  def no_comment
  end
end
EOC
      replacement = <<-EOC
class SmallClass
  # this is the first comment
  def no_comment
  end
end
EOC
      mock_file(method, replacement)
      code_comments(:no_comment).export! 1
    end
    
    it "should replace file comment" do
      file = <<-EOC
# This is a file comment

# This is a class comment
class Something
end
EOC
      replacement = <<-EOC
# This is a new file comment

# This is a class comment
class Something
end
EOC
      mock_file(file, replacement)
      code_comments(:file_comment).export! 2
    end

    it "should allow for first file comment" do
      file = <<-EOC
# This is a class comment
class Something
end
EOC
      replacement = <<-EOC
# This is the first of many

# This is a class comment
class Something
end
EOC
      mock_file(file, replacement)
      code_comments(:first_file_comment).export! 1
    end
    
    it "should ignore bash stuff" do
      file = <<-EOC
#! ruby /usr/env/ruby

# This is a class comment
class Something
end
EOC
      replacement = <<-EOC
#! ruby /usr/env/ruby

# This is the first of many

# This is a class comment
class Something
end
EOC
      mock_file(file, replacement)
      code_comments(:first_file_comment).export! 1
    end

  end
end