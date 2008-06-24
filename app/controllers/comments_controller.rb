class CommentsController < ApplicationController
  def show
    @comment = CodeComment.find(params[:id])
  end
  
  def update
    @comment = CodeComment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      flash[:notice] = "Comment properly updated"
      flash[:comment] = @comment.id
      redirect_to doc_path(@comment)
    end
  end
end
