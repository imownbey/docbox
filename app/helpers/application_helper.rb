# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def rdoc_html_parse(bare)
    unless bare.nil?
      p = SM::SimpleMarkup.new
      h = SM::ToHtml.new
      
      p.convert(bare, h).gsub(/(<pre>(.*?)<\/pre>)/m) do |code|
        highlight(unescape_and_strip($2))
      end
    end
  end
  
  def highlight(code)
    Syntaxi::line_number_method = 'none'
    Syntaxi.new("[code lang=\"ruby\"]\n" + code + "\n[/code]").process
  end
  
  private
  
  def link_symbol(symbol)
    name = symbol
    if name[0,1] == '#'
      lookup = name[1..-1]
      name = lookup
    else
      lookup = name
    end

    if /([A-Z]\w*)[.\#](\w+[!?=]?)/ =~ lookup
      container = $1
      method = $2
      ref = find_symbol(name, container, method)
    elsif /([A-Za-z]\w*)[.\#](\w+(\([\.\w+\*\/\+\-\=\<\>]+\))?)/ =~ lookup
      container = $1
      method = $2
      ref = find_symbol(name, container, method)
    else
      ref = find_symbol(name, lookup)
    end
    ref
  end
  
  def find_symbol(name, container, method = '')
    if method
      symbol = @methods[:all].select {|m| m.name == method}.first
      if symbol
        link_to name, "#meth-#{symbol.name.to_url}"
      else
        if container_symbol = CodeContainer.find_by_full_name(container)
          if symbol = container_symbol.code_methods.find_by_name(method)
            link_to name, doc_path(symbol.path)
          else
            name
          end
        else
          name
        end
      end
    end
  end
  
  def unescape_and_strip(text)
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
