class CommentVersion < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_comment
  
  named_scope :recent, :order => ['created_at DESC']
  named_scope :before, lambda {|num| {:conditions => ['version < ?', num]} }
  named_scope :acceptable, :conditions => ['skip IS false']
end
