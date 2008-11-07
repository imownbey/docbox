class InFile < ActiveRecord::Base
  belongs_to :code_file
  belongs_to :code_container
end
