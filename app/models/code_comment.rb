class CodeComment < ActiveRecord::Base
  
  class VersionNotExported < ArgumentError; end
  
  belongs_to :owner, :polymorphic => true
  belongs_to :user
  has_many :versions
  
  before_update :create_version
  
  # For the sake of STI
  def owner_type=(sType)
    super(sType.to_s.classify.constantize.base_class.to_s)
  end
  
  def create_version
    if self.body_changed?
      Version.create(
        :user_id => (self.user_id_changed? ? self.user_id_was : self.user_id), 
        :body => self.body_was, 
        :exported => self.exported?, 
        :code_comment => self,
        :version => self.version
      )
      self.exported = false
      self.version += 1
    end
  end
  
  def v number
    if self.version == number
      self
    else
      self.versions.find_by_version(number)
    end
  end
  
  def export! version_number
    version = self.v version_number
    pre_version = self.v version_number - 1
    raise VersionNotExported.new("Previous version not exported.") unless pre_version.exported?
    if f = export(pre_version, version)
      version.exported = true
      version.save
    else
      false
    end
  end
  
  private
  
  def export v1, v2
    @file = File.new('foobar', 'r+')
    pre_regexp = build_regexp(v1.body)
    # If the parent is a class we must make sure its in proper context
    if owner.code_container.is_a? CodeClass
      start, context, ending = get_context
    else
      start = ''
      ending = ''
      context = @file.read
    end
    replace_string = build_string(v2.body)
    context = context.sub(pre_regexp, replace_string)
    @file.rewind
    @file.puts(start + context + ending)
    @file.close
  end
  
  def get_context
    raise unless @file
    buffer = ''
    context = ''
    future = ''
    in_context = false
    in_future = false
    @file.each_line do |line|
      if in_future
        future += line
        next
      end

      case line
      when Regexp.new(next_line_str)
        in_context = false
        in_future = true
        context += line # We add it any way just so we have an ending point (if there is no comment)
        next
      when owner.code_container.line_code # This defines the class
        in_context = true
      end
      
      if in_context
        context += line
      else
        # we arent in future or context, must just be in buffer
        buffer += line
      end
    end # file.each_line
    [buffer, context, future]
  end
  
  # Builds regex with the following:
  #   \1 = Tabbing before comment
  #   \2 = Tabbing/newlining before def
  #   \3 = Def syntax
  def build_regexp v1
    comment = commentify(v1)
    regexp = comment.split("\n").collect {|line|
      "(\\s*)#{line}"
    }.join("\n")
    regexp += "\n(\\s*)(#{next_line_str}[^\\n]*)"
    Regexp.new(regexp)
  end
  
  def build_string string
    comment = commentify(string)
    string = comment.split("\n").collect {|line|
      "\\1#{line}"
    }.join("\n")
    string + "\n\\2\\3"
  end
  
  # TODO: Make this support =begin and =end
  def commentify string
    string.split("\n").collect { |line| "\# #{line}"}.join("\n")
  end
  
  def next_line_str
    case self.owner.class.to_s
    when 'CodeMethod'
      "def #{owner.name}"
    when 'CodeClass'
      "#{owner.line_code}"
    when 'CodeModule'
      "module\\s+[^\\s]*#{owner.name}"
    when 'CodeRequire'
      "require\\s+['\"]#{owner.name}['\"]"
    when 'CodeInclude'
      "include\\s+#{owner.name}"
    when 'CodeConstant'
      "#{owner.name}\\s+=\\s+#{owner.value}"
    end
  end
end
