class Comment < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  
  # For the sake of STI
  def owner_type=(sType)
    super(sType.to_s.classify.constantize.base_class.to_s)
  end
end
