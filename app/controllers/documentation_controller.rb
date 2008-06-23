class DocumentationController < ApplicationController
  
  def show
    @objects = get_object(params[:tokens])
    if @objects
      # render stuff here
    else
      # 404
    end
  end
  
  private
  
  def get_object(params)
    objects = []
    params.each_with_index do |token, index|
      objects[index] = find_token token, (objects[index - 1] || nil)
    end
    objects
  end

  def find_token(token, parent)
    if parent
      parent.code_methods.find_by_name(token) || parent.code_objects.find_by_name(token) || parent.code_containers.find_by_name(token)
    else
      CodeContainer.find_by_name(token)
    end
  end
end
