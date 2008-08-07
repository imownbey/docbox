class AdminController < ApplicationController
  before_filter :login_required, :get_error_count
  
  def errors
    @errors = Error.unfixed.all
  end
  
  private
  
  def authorized?
    unless (!current_user.nil?) && current_user.admin?
      flash[:notice] = "You must be admin to do that."
      redirect_to login_path
    else
      true
    end
  end
  
  def get_error_count
    @error_count = Error.unfixed.count(:all)
  end
end
