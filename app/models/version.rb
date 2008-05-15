class Version < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_comment
end
