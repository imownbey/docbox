class FormatHtml < SM::ToHtml
  # We have to hold the methods for crossref
  def initialize(methods)
    @methods = methods
  end
  
  def handle_special_CROSSREF(special)
    name = special.text
    if name[0,1] == '#'
      lookup = name[1..-1]
      name = lookup
    else
      lookup = name
    end

    # Find class, module, or method in class or module.
    if /([A-Z]\w*)[.\#](\w+[!?=]?)/ =~ lookup
      container = $1
      method = $2
      ref = find_symbol(container, method)
    elsif /([A-Za-z]\w*)[.\#](\w+(\([\.\w+\*\/\+\-\=\<\>]+\))?)/ =~ lookup
      container = $1
      method = $2
      ref = find_symbol(container, method)
    else
      ref = find_symbol(lookup)
    end

    if ref and ref.document_self
      "<a href=\"#{ref.as_href(@from_path)}\">#{name}</a>"
    else
      name
    end
  end
  
  def find_symbol(a, b='')
    p a, b
  end
end

module MarkUp
  def self.convert(content, methods)
    Syntaxi::line_number_method = 'none'
    
    unless defined? @markup
      @markup = SM::SimpleMarkup.new

      # class names, variable names, or instance variables
      @markup.add_special(/(
                             \w+(::\w+)*[.\#]\w+(\([\.\w+\*\/\+\-\=\<\>]+\))?  # A::B.meth(**) (for operator in Fortran95)
                           | \#\w+(\([.\w\*\/\+\-\=\<\>]+\))?  #  meth(**) (for operator in Fortran95)
                           | \b([A-Z]\w*(::\w+)*[.\#]\w+)  #    A::B.meth
                           | \b([A-Z]\w+(::\w+)*)       #    A::B..
                           | \#\w+[!?=]?                #    #meth_name 
                           | \b\w+([_\/\.]+\w+)*[!?=]?  #    meth_name
                           )/x, 
                          :CROSSREF)
    end
    unless defined? @html_formatter
      @html_formatter = FormatHtml.new(methods)
    end
    content = @markup.convert(content, @html_formatter)
    content.gsub(/(<pre>(.*?)<\/pre>)/m) do |code|
      Syntaxi.new("[code lang=\"ruby\"]\n" + unescape_and_strip($2) + "\n[/code]").process
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