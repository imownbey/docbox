class CommentsController < ApplicationController
  def show
    @comment = CodeComment.find(params[:id])
  end
  
  def update
    @comment = CodeComment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      flash[:notice] = "Comment properly updated"
      flash[:comment] = @comment.id
      options = ((@comment.owner.is_a? CodeMethod) ? { :anchor => @comment.owner.name } : {})
      redirect_to doc_path(@comment, options)
    else
      render :action => "edit", :controller => "comments", :id => @comment.id
    end
  end
end
