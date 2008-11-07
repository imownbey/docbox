class CommentsController < ApplicationController
  before_filter :find_comment, :except => [:new, :create]
  def show
  end
  
  def diff
    @version = @comment.v(params[:v])
    @current = @comment
  end
  
  def edit
    @source = @comment.owner.try(:source_code)
  end
  
  def update
    if @comment.update_attributes(params[:code_comment].merge({:user => current_user}))
      flash[:notice] = "Comment properly updated"
      flash[:comment] = @comment.id
      options = ((@comment.owner.is_a? CodeMethod) ? { :anchor => @comment.owner.name } : {})
      if @comment.owner.try(:main_comment)
        redirect_to doc_path
      else
        redirect_to doc_path(@comment.owner.path, options)
      end
    else
      render :action => "edit", :controller => "comments", :id => @comment.id
    end
  end
  
  def new
    @commentable = get_object(params[:tokens], false).last
    @comment = CodeComment.new(:owner => @commentable, :version => 1)
    @source = @comment.owner.try(:source_code)
    render :action => "edit", :controller => "comments"
  end
  
  def create
    @commentable = CodeContainer.find(params[:id])
    if @commentable.code_comment.nil?
      @commentable.code_comment = CodeComment.create(params[:code_comment].merge({:user => current_user}))
    else
      @commentable.code_comment.update_attributes params[:code_comment].merge({:user => current_user})
    end
    redirect_to doc_path(@commentable.path)
  end
  
  private
  
  def find_comment
    @comment = CodeComment.find(params[:id])
  end
end
