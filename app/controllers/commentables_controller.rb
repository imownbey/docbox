class CommentablesController < ApplicationController
  before_filter :get_commentable
  
  def show
  end

  private
  
  def get_commentable
    id = params[:id]
    @commentable = (CodeContainer.find_by_id(id) || CodeMethod.find_by_id(id) || CodeObject.find_by_id(id))
  end
end
