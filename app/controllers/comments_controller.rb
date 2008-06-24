class CommentsController < ApplicationController
  def show
    @comment = CodeComment.find(params[:id])
  end
end
