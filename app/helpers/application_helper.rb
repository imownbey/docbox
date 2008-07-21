# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def rdoc_html_parse(bare)
    unless bare.nil?
      Syntaxi::line_number_method = 'none'
      p = SM::SimpleMarkup.new
      h = SM::ToHtml.new
      
      p.convert(bare, h).gsub(/(<pre>(.*?)<\/pre>)/m) do |code|
        Syntaxi.new("[code lang=\"ruby\"]\n" + unescape_and_strip($2) + "\n[/code]").process
      end
    end
  end
  
  def unescape_and_strip(text)
    p text
    if text =~ /^(\s+)/
      indent = $1.length
      text.split("\n").collect do |line|
        line = line[(indent - 1)..-1]
        line = CGI.unescapeHTML(line) unless line.nil?
        line
      end
    end.join("\n")
  end
end
