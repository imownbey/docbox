# Evan Weaver!
# => http://blog.evanweaver.com/articles/2006/09/03/smart-plaintext-wrapping/
# Except if it is tabbed, then you dont wrap it
class String

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
end

class << ActiveRecord::Base
  def create_or_update(options = {})
    self.create_or_update_by(:id, options)
  end

  def create_or_update_by(field, options = {})
    find_value = options.delete(field)
    record = find(:first, :conditions => {field => find_value}) || self.new
    record.send field.to_s + "=", find_value
    record.attributes = options
    record.save!
    record
  end
  
  def create_or_update_by_and(field1, field2, options = {})
    find_value1 = options.delete(field1)
    find_value2 = options.delete(field2)
    record = find(:first, :conditions => {field1 => find_value1, field2 => find_value2}) || self.new
    record.send "#{field1.to_s}=", find_value1
    record.send "#{field2.to_s}=", find_value2
    record.attributes = options
    record.save!
    record
  end

  def method_missing_with_create_or_update(method_name, *args)
    if match = method_name.to_s.match(/create_or_update_by_([a-z0-9_]+)/)
      if match[1] =~ /([a-z0-9_]+)_and_([a-z0-9_]+)/
        create_or_update_by_and($1.to_sym, $2.to_sym, *args)
      else
        field = match[1].to_sym
        create_or_update_by(field,*args)
      end
    else
      method_missing_without_create_or_update(method_name, *args)
    end
  end

  alias_method_chain :method_missing, :create_or_update
end