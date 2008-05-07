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
    @import.should change(Container, :count).by(3)
  end
  
  it "should create 1 new doc" do
    @import.should change(Doc, :count).by(1)
  end
  
  it "should create 1 new mod" do
    @import.should change(Mod, :count).by(1)
  end
  
  it "should create 1 new klass" do
    @import.should change(Klass, :count).by(1)
  end
  
  it "should create 4 new methods" do
    @import.should change(Meth, :count).by(4)
  end
  
  it "should create 1 private method" do
    @import.call
    [Meth.find_by_visibility('private')].length.should == 1
  end

  it "should require duckies" do
    @import.should change(Require, :count).by(1)
  end
  
  it "should give proper parent" do
    @import.call
    Meth.find_by_name('no_doc').container.should == Klass.find_by_name('SimpleClass')
  end
  
  it "should create 2 comments" do
    @import.should change(Comment, :count).by(2)
  end
end
