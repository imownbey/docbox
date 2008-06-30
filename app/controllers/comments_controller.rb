class CommentsController < ApplicationController
  before_filter :find_comment, :except => [:new, :create]
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
  
  def new
    @commentable = get_object(params[:tokens], false).last
    p @commentable.to_path
    @comment = CodeComment.new
  end
  
  def create
    @commentable = get_object(params[:tokens], false).last
    @commentable.code_comment = CodeComment.create(params[:code_comment].merge({:user => current_user}))
  end
  
  private
  
  def find_comment
    @comment = CodeComment.find(params[:id])
  end
end
