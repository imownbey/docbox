class CommentsController < ApplicationController
  before_filter :find_comment
  def show
  end
  
  def edit
  end
  
  def update
    if @comment.update_attributes(params[:code_comment].merge({:user => current_user}))
      flash[:notice] = "Comment properly updated"
      flash[:comment] = @comment.id
      options = ((@comment.owner.is_a? CodeMethod) ? { :anchor => @comment.owner.name } : {})
      redirect_to doc_path(@comment, options)
    else
      render :action => "edit", :controller => "comments", :id => @comment.id
    end
  end
  
  private
  
  def find_comment
    @comment = CodeComment.find(params[:id])
  end
end
