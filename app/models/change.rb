class Change < ActiveRecord::Base
  named_scope :deleted, :conditions => [:type => 'Delete']
  
  belongs_to :owner, :polymorphic => true
  #belongs_to :tag
end
