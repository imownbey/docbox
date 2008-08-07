class AdminController < ApplicationController
  before_filter :login_required
  
  
  
  private
  
  def authorized?
    unless current_user.admin?
      flash[:notice] = "You must be admin to do that."
      redirect_to login_path
    end
  end
end
