require 'mixins'
class CodeComment < ActiveRecord::Base
  include TokenParams
  # Regexp for stuff
  REGEXP = {}
  # =begin and =end stuff
  REGEXP[:begin] = {}
  REGEXP[:begin][:start] = /^=begin\s+rdoc/
  REGEXP[:begin][:finish] = /^=end/
  
  # Pound (#) stuff
  REGEXP[:pound] = /^\s*#/
  
  # Bash stuff (#! envruby)
  REGEXP[:bash] = /^\s*#!/
  
  class VersionNotExported < ArgumentError; end
  class AlreadyExported < ArgumentError; end
  
  belongs_to :owner, :polymorphic => true
  belongs_to :user
  has_many :versions
  
  before_update :create_version
  
  # For the sake of STI
  def owner_type=(sType)
    super(sType.to_s.classify.constantize.base_class.to_s)
  end
  
  # This is called by the RDoc importer. It is only used when imported.
  def exported_body=(comment)
    self.raw_body = comment
    self.body = strip(comment)
    self.exported = true # Only rdoc import uses exported_body, so this means its been exported
    self.uses_begin = (comment =~ REGEXP[:pound]).nil?
  end
  
  # Before update, creating the previous version
  def create_version
    if self.body_changed?
      Version.create(
        :user_id => (self.user_id_changed? ? self.user_id_was : self.user_id), 
        :body => self.body_was, 
        :exported => self.exported?, 
        :code_comment => self,
        :version => self.version,
        :skip => self.skip,
        :uses_begin => self.uses_begin
      )
      self.exported = false
      self.version += 1
    end
  end
  
  # Grabs the version of a comment based on number
  def v number
    if self.version == number
      self
    else
      self.versions.find_by_version(number)
    end
  end
  
  # Export the version number and set exported to true
  def export! version_number
    version = self.v version_number
    raise AlreadyExported.new("Version already exported") if version.exported?
    unless version.skip?
      pre_version = good_version_before(version_number) unless version == 1
      raise VersionNotExported.new("Previous version not exported.") unless pre_version.nil? || pre_version.exported?
      if f = export(pre_version, version)
        version.exported = true
        version.save
      else
        false
      end
    end
  end
  
  private
  
  # Strip a comment of anything except the meat
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
  
  def good_version_before(n)
    self.versions.recent.acceptable.before(n).first
  end
  
  # Takes two versions, and exports the second one.
  def export v1, v2
    @file = File.new('foobar', 'r+')
    if v1.nil? && owner.is_a?(CodeFile)
      # v1 is nil and owner is a file, just throw it at start at file
      file_body = inject_at_file_start v2.body
    else
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
      context = context.sub(pre_regexp, replace_string)
      file_body = start + context + ending
    end
    @file.rewind
    @file.puts(file_body)
    @file.close
    
    git = Git.open(RAILS_ROOT + '/code')
    git.config('user.name', v2.user.name)
    git.config('user.email', v2.user.email)
    git.commit_all("Documentation update for #{owner.name}")
  end
  
  # Called when there is no previous version and creating a new file comment
  # Skips inital bash stuff
  def inject_at_file_start body
    raise unless @file
    body = commentify(body)
    pre, future, comment_added = '', '', false
    @file.each_line do |line|
      unless comment_added
        if line =~ REGEXP[:bash]
          # Bash, add to pre
          pre << line
        else
          if line =~ /^\s*$/
            # Just space, add to pre
            pre << line
          else
            comment_added = true
            future << line
          end
        end
      else
        # Comment has been added, just add to future
        future << line
      end
    end
    pre + body + "\n\n" + future
  end
  
  # Used to get context if comments parent is a file. Thus context is the start of a file (before 
  # class or method declarations)
  def get_file_start
    raise unless @file
    context, future = '', ''
    in_context, seen_comment = true, false
    @file.each_line do |line|
      if in_context # We are still adding to context
        unless seen_comment # We have not seen the comment, so add to context and look for it
          case line
          when REGEXP[:bash]
            # Bashfun
            context << line
          when /^\s+$/
            # Blank line
            context << line
          when REGEXP[:pound]
            # This is most likely the first comment
            seen_comment = true
            context << line
          end
        else # We have seen the comment, so continue until the end of it
          # Seen teh comment, look to keep seeing it
          if line =~ REGEXP[:pound]
            context << line
          else # Line does not start with #, out of context
            future << line
            in_context = false
            next
          end
        end
      else # We are not in context, just add to future
        future << line
      end
    end
    [context, future]
  end
  
  # Gets context of a comment. This means from start of class declartion => definition of method or require
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
        buffer += line
        in_context = true
        next
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
    if v1.nil? && raw_body.nil?
      regexp = "((\\s*))(#{next_line_str}[^\\n]*)"
    else
      comment = commentify(raw_body || v1)
      regexp = comment.split("\n").collect {|line|
        if line =~ REGEXP[:begin][:start] || line =~ REGEXP[:begin][:finish]
          # This is a begin or end, just add the line
          line
        else
          n ||= true # Counter to see if this is the first, in which case we capture whitespace
          # If it uses begin, dont capture whitespace since it does not matter, we just tab it in
          if n && !uses_begin?
            start = "(\\s*)"
          else
            start = "\\s*"
          end
          n = false
          start + line
        end
      }.join("\n")
      regexp += "\n(\\s*)(#{next_line_str}[^\\n]*)" unless self.owner.is_a? CodeFile
    end
    Regexp.new(regexp)
  end
  
  # Builds the replacement string based on a comment. Adds #'s and formats for regexp
  def build_string string, no_v1 = false
    if uses_begin?
      string = commentify(string)
    else
      comment = commentify(string)
      string = comment.split("\n").collect {|line|
        "\\1#{line}"
      }.join("\n")
    end
    string += "\n\\2\\3" unless self.owner.is_a? CodeFile
    string
  end
  
  # Makes a comment a comment. Addes # or =begin=end
  def commentify string
    string = string.wrap(60, 0, true, true)
    if uses_begin?
      string = string.split("\n").collect { |line| "  #{line}" }.join("\n")
      string = "=begin rdoc\n#{string}\n=end"
    else
      string = string.split("\n").collect { |line| "\# #{line}"}.join("\n")
    end
    string
  end
  
  # Get the definition string, based on the owner
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
