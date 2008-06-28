class CommentablesController < ApplicationController
  before_filter :get_commentable
  
  def show
  end
  
  def new
  end
  
  def create
    @comment = CodeComment.create(params[:code_comment])
    unless @comment.new_record?
      flash[:notice] = "Your comment has been added."
      redirect_to doc_path(@commentable)
    else
      render :action => 'new'
    end
  end
  
  private
  
  def get_commentable
    id = params[:id]
    @commentable = (CodeContainer.find_by_id(id) || CodeMethod.find_by_id(id) || CodeObject.find_by_id(id))
  end
end
