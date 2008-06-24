require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CommentsController, "GET #show" do
  fixtures :all
    
  act! { get :show, :id => 1 }
  
  before(:each) do
    @comment = code_comments(:not_current)
    CodeComment.stub!(:find).and_return(@comment)
  end
  
  it_assigns :comment
end

describe CommentsController, "PUT #update" do
  fixtures :all
  
  before(:each) do
    @comment = code_comments(:nested_class)
    CodeComment.stub!(:find).and_return(@comment)
    @comment.stub!(:id).and_return(1)
    @comment.stub!(:update_attributes).and_return(true)
  end
  
  act! { put :update, :id => 1, :comment => {}}
  it_assigns :comment, :flash => {:notice => :not_nil, :comment => 1}
  it_redirects_to { doc_path(@comment) }
end
