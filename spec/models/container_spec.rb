require File.dirname(__FILE__) + '/../spec_helper'

describe Container do
  before(:each) do
    @container = Container.new
  end

  it "should be valid" do
    @container.should be_valid
  end
end
