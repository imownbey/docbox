require File.dirname(__FILE__) + '/../spec_helper'
require 'rdoc/rdoc'
require File.dirname(__FILE__) + '/../../lib/parsing'

##
# This silences the RDoc output so
# we dont muddy up the console
module RDoc
  class RDoc
    $stderr.reopen(File.new('/tmp/stderr.docbox', 'w'))
  end
end

describe RDoc do
  before(:each) do
    @import = lambda {
      @rdoc = RDoc::RDoc.new
      @rdoc.import! %W{#{File.dirname(__FILE__)}/../fixtures/sample.rb}
    }
  end

  it "should create three containers" do
    @import.should change(CodeContainer, :count).by(4)
  end
  
  it "should create 1 new doc" do
    @import.should change(CodeFile, :count).by(1)
  end
  
  it "should create 1 new mod" do
    @import.should change(CodeModule, :count).by(1)
  end
  
  it "should create 2 new klass" do
    @import.should change(CodeClass, :count).by(2)
  end
  
  it "should create 4 new methods" do
    @import.should change(CodeMethod, :count).by(4)
  end
  
  it "should create 1 private method" do
    @import.call
    [CodeMethod.find_by_visibility('private')].length.should == 1
  end

  it "should require duckies" do
    @import.should change(CodeRequire, :count).by(1)
  end
  
  it "should give proper parent" do
    @import.call
    CodeMethod.find_by_name('no_doc').code_container.should == CodeClass.find_by_name('SimpleClass')
  end
  
  it "should create 3 comments" do
    @import.should change(CodeComment, :count).by(3)
  end
  
  it "should create a heredoc comment" do
    @import.call
    CodeClass.find_by_name('SomeOtherClass').code_comment.should be_uses_begin
    CodeClass.find_by_name('SimpleClass').code_comment.should_not be_uses_begin
  end
  
  it "should strip comments properly" do
    @import.call
    CodeClass.find_by_name('SimpleClass').code_comment.body.should == "This is a class comment"
  end
end

describe RDoc, "file comments" do  
  it "should only update comments by 1" do
    lambda {
      @rdoc = RDoc::RDoc.new
      @rdoc.import! %W{#{File.dirname(__FILE__)}/../fixtures/file_comments.rb}
    }.should change(CodeComment, :count).by(1)
  end
  
  it "should update 2 comments when there are 2 comments" do
    lambda {
      @rdoc = RDoc::RDoc.new
      @rdoc.import! %W{#{File.dirname(__FILE__)}/../fixtures/file_comments2.rb}
    }.should change(CodeComment, :count).by(2)
  end
end
