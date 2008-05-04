class Container < ActiveRecord::Base
  has_many :code_objects
  has_many :methods
  belongs_to :parent, :class_name => 'Container'
  has_one :comment, :as => :owner, :dependent => :destroy
end

class Klass < Container
end

class Mod < Container
end

class Doc < Container
end