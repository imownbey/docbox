class Error < ActiveRecord::Base
  named_scope :unfixed, :conditions => {:fixed => false}
  
  def pre_version=(version)
    self.pre_version_body = version.body
  end
  
  def version=(version)
    self.name = get_name(version)
    self.version_body = version.body
  end
  
  private
  
  def get_name(version)
    if version.is_a? CodeComment
      version.owner.full_name
    else
      version.code_comment.owner.full_name
    end
  end
end
