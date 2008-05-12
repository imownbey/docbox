class Comment < ActiveRecord::Base
  
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
        :comment => self,
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
    pre_regexp = build_regexp(v1.body)
    p pre_regexp
    replace_string = build_string(v2.body)
    File.open('foobar') do |f|
      replace = f.read.sub!(pre_regexp, replace_string)
      f.rewind
      f.puts(replace)
    end
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
    when 'Meth'
      "def #{owner.name}"
    when 'Klass'
      "class\\s+[^\\s]*#{owner.name}"
    when 'Mod'
      "module\\s+[^\\s]*#{owner.name}"
    when 'Require'
      "require\\s+['\"]#{owner.name}['\"]"
    when 'Include'
      "include\\s+#{owner.name}"
    when 'Constant'
      "#{owner.name}\\s+=\\s+#{owner.value}"
    end
  end
end
