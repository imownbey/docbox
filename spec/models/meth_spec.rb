require File.dirname(__FILE__) + '/../spec_helper'

describe Meth do
  before(:each) do
    @meth = Meth.new
  end

  it "should be valid" do
    @meth.should be_valid
  end
end
