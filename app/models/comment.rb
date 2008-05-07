class Comment < ActiveRecord::Base
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
end
