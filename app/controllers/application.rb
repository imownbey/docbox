# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '50b31e962fd5a59413682eeff21dda01'
  
  def render_404
    render :file => RAILS_ROOT + "/public/404.html", :status => 404
  end
  
  def get_object(params, preload = true)
    objects = []
    params.each_with_index do |token, index|
      objects[index] = find_token token, (objects[index - 1] || nil), (preload && (params.length == index + 1))
    end
    objects
  end

  def find_token(token, parent, last = false)
    if last && token.valid_constant?
      conditions = {:include => [:code_methods]}
    else
      conditions = {}
    end
    
    if parent
      parent.code_methods.find_by_name(token, conditions) || parent.code_objects.find_by_name(token, conditions) || parent.code_containers.find_by_name(token, conditions)
    else
      CodeContainer.find_by_name(token, conditions)
    end
  end
end