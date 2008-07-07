# Evan Weaver!
# => http://blog.evanweaver.com/articles/2006/09/03/smart-plaintext-wrapping/
# Except if it is tabbed, then you dont wrap it
class String
  def valid_constant?
    !(/\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ self).nil?
  end

  def wrap(width, hanging_indent = 0, magic_lists = false, skip_tabs = true)
    lines = self.split(/\n/)

    lines.collect! do |line|
      if line =~ /^\s+/ && skip_tabs
        line
      else
        if magic_lists 
          line =~ /^([\s\-\d\.\:]*\s)/
        else 
          line =~ /^([\s]*\s)/
        end

        indent = $1.length + hanging_indent rescue hanging_indent

        buffer = ""
        first = true

        while line.length > 0
          first ? (i, first = 0, false) : i = indent              
          pos = width - i

          if line.length > pos and line[0..pos] =~ /^(.+)\s/
            subline = $1
          else 
            subline = line[0..pos]
          end
          buffer += " " * i + subline + "\n"
          line.tail!(subline.length)
        end
        buffer[0..-2]
      end
    end

    lines.join("\n")

  end

  def tail!(pos)
    self[0..pos] = ""
    strip!
  end

end


class Object
  ##
  # http://ozmm.org/posts/try.html
  #
  #   @person ? @person.name : nil
  # vs
  #   @person.try(:name)
  def try(method)
    if self.is_a?(NilClass)
      nil
    else
      send method if respond_to? method
    end
  end
<<<<<<< HEAD:lib/core_ext.rb
end
=======
end

<<<<<<< HEAD:lib/core_ext.rb
>>>>>>> 10a2528169e1fbd0ccfe1a2257c9820e3db3b2ed:lib/core_ext.rb
=======
>>>>>>> mrneighborly/master:lib/core_ext.rb
