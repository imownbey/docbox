# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def rdoc_html_parse(bare)
    RDoc::Markup::ToHtml.new.convert(bare)
  end
end
