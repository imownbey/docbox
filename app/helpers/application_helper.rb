# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def tokens_path(object)
    path = []
    while object
      path << "#{object.name}"
      object = object.code_container
      object = nil if object.is_a? CodeFile
    end
    path.reverse.join('/')
  end
end
