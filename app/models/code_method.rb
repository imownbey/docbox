class CodeMethod < ActiveRecord::Base
  belongs_to :code_container
  has_one :code_comment, :as => :owner, :dependent => :destroy
end
