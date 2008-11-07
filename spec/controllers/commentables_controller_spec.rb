require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CommentablesController do
# fixtures :all
# describe "GET #new" do
#   before(:each) do
#     @commentable = code_containers(:colon_class)
#     CodeMethod.stub!(:find_by_id).and_return(@commentable)
#   end
#   act! { get :new, :id => 1 }
#   it_assigns :commentable
# end
# 
# describe "GET #show" do
#   before(:each) do
#     @commentable = code_containers(:colon_class)
#     CodeMethod.stub!(:find_by_id).and_return(@commentable)
#   end
#   act! { get :show, :id => 1 }
#   it_assigns :commentable
# end
# 
# 
# describe "POST #create" do
#   before(:each) do
#     @commentable = code_containers(:colon_class)
#     CodeMethod.stub!(:find_by_id).and_return(@commentable)
#     @comment = mock_model CodeComment, :new_record? => false, :errors => []
#     CodeComment.stub!(:create).and_return(@comment)
#   end
#   
#   describe "working" do
#     act! {post :create, :commentable_id => 1, :comment => {:body => "foo"}}
#     before(:each) do
#       @comment.stub!(:new_record?).and_return(false)
#     end
#     
#     it_assigns :commentable, :comment, :flash => { :notice => :not_nil }
#     it_redirects_to { doc_path @commentable }
#   end
#   
#   describe "failing" do
#     act! {post :create, :commentable_id => 1, :comment => {:body => "foo"}}
#     before(:each) do
#      @comment.stub!(:new_record?).and_return(true)
#     end
#
#     it_assigns :commentable, :comment
#     it_renders :template, :new
#   end
# end
end
