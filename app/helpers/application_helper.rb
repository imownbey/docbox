# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def rdoc_html_parse(bare)
    p = SM::SimpleMarkup.new
    h = SM::ToHtml.new
    
    p.convert(bare, h)
  end
end
