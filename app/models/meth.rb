class Meth < ActiveRecord::Base
  belongs_to :container
  has_one :comment, :as => :owner, :dependent => :destroy
end
