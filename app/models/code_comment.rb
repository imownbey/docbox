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
  
  def exported_body=(comment)
    self.raw_body = comment
    self.body = strip(comment)
    self.exported = true # Only rdoc import uses exported_body, so this means its been exported
  end
  
  def uses_begin?
    (raw_body =~ /^\s*#/).nil? # =begin doesnt have any #
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
    pre_version = self.v version_number - 1 unless version == 1
    raise VersionNotExported.new("Previous version not exported.") unless pre_version.nil? || pre_version.exported?
    if f = export(pre_version, version)
      version.exported = true
      version.save
    else
      false
    end
  end
  
  private
  
  def strip(comment)
    comment.split("\n").inject([]) do |new_comment, line|
      if line =~ /(=begin.*|=end)/ || line =~ /^\s*#+\s*$/
        # This is fluff
        new_comment
      else
        new_comment << line.gsub(/\s*#\s*/, '')
      end
    end.join("\n")
  end
  
  def export v1, v2
    @file = File.new('foobar', 'r+')
    body = v1.body rescue nil
    pre_regexp = build_regexp(body)
    # If the parent is a class we must make sure its in proper context
    if owner.true_container.is_a? CodeClass
      start, context, ending = get_context
    else
      if owner.is_a? CodeFile
        start = ''
        context, ending = get_file_start
      else
        start = ''
        ending = ''
        context = @file.read
      end
    end
    replace_string = build_string(v2.body, (true if v1.nil?))
    p pre_regexp
    context = context.sub(pre_regexp, replace_string)
    @file.rewind
    @file.puts(start + context + ending)
    @file.close
  end
  
  def get_file_start
    raise unless @file
    context = ''
    future = ''
    in_context = true
    seen_comment = false
    uses_begin = false
    @file.each_line do |line|
      if in_context # We are still adding to context
        unless seen_comment # We have not seen the comment, so add to context and look for it
          if line =~ /^\s*#!/
            # Bashfun
            context << line
          elsif line =~ /^\s+$/
            # Blank line
            context << line
          elsif line =~ /^\s*#/
            # This is most likely the first comment
            seen_comment = true
            context << line
          elsif line =~ /^=begin\s+rdoc/
            #this is the begin of a comment
            context << line
            seen_comment = true
            uses_begin = true
          end
        else # We have seen the comment, so continue until the end of it
          # Seen teh comment, look to keep seeing it
          if uses_begin
            unless line =~ /^=end\s*$/
              context << line
              in_context = false
            else
              context << line
            end
          else
            if line =~ /\s*#/
              context << line
            else
              context << line
              in_context = false
            end
          end
        end
      else # We are not in context, just add to future
        future << line
      end
    end
    p context
    [context, future]
  end
  
  def get_context
    raise unless @file
    buffer = ''
    context = ''
    future = ''
    in_context = false
    in_future = false
    @file.each_line do |line|
      case line
      when Regexp.new(next_line_str)
        if in_context
          in_context = false
          in_future = true
          context += line # Add the last line (def ...) for sanitys sake
          next
        end
      when owner.true_container.line_code # This defines the class
        in_context = true
      end
      
      if in_context
        context += line
      elsif in_future
        future += line
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
  def build_regexp v1 = nil
    if v1.nil?
      regexp = "(\\s*)(#{next_line_str}[^\\n]*)"
    else
      comment = commentify(v1)
      regexp = comment.split("\n").collect {|line|
        "(\\s*)#{line}"
      }.join("\n")
      regexp += "\n(\\s*)(#{next_line_str}[^\\n]*)"
    end
    Regexp.new(regexp)
  end
  
  def build_string string, no_v1 = false
    comment = commentify(string)
    string = comment.split("\n").collect {|line|
      "\\1#{line}"
    }.join("\n")
    string += if no_v1
                "\\1\\2"
              else
                "\n\\2\\3"
              end
    string
  end
  
  # TODO: Make this support =begin and =end
  def commentify string
    string.split("\n").collect { |line| "\# #{line}"}.join("\n")
  end
  
  def next_line_str
    case self.owner
    when CodeMethod
      "def #{owner.name}"
    when CodeClass
      "#{owner.line_code}"
    when CodeModule
      "module\\s+[^\\s]*#{owner.name}"
    when CodeRequire
      "require\\s+['\"]#{owner.name}['\"]"
    when CodeInclude
      "include\\s+#{owner.name}"
    when CodeConstant
      "#{owner.name}\\s+=\\s+#{owner.value}"
    end
  end
end
