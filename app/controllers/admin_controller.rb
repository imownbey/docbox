class AdminController < ApplicationController
  before_filter :login_required
  
  def authorize
  
  def create_user_authorization
    
  end
  
  private
  
  def authorized?
    unless current_user.admin?
      flash[:notice] = "You must be admin to do that."
      redirect_to login_path
    end
  end
end
