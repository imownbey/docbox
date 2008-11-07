module TokenParams
  def path
    path = []
    object = (CodeComment === self ? owner : self)
    while object
      path << "#{object.name}"
      object = object.code_container
      object = nil if object.is_a? CodeFile
    end
    
    path.reverse
  end
  
  def fully_qualified_name
    path = self.path
    
    if self.class == CodeMethod
      method_name = path.pop
      (path.join("::")) + "##{method_name}"
    else
      path.join("::")
    end
  end
end

module Documentable
  def self.included(base)
    base.class_eval do
      has_one :code_comment, :as => :owner, :dependent => :destroy
      belongs_to :code_file
      has_many :changes
      has_many :tags, :through => :changes
      
      # Creates a remove instead of deleting file
      def remove
        Delete.create(:owner => self)
        self.destroy
      end
    end
  end
end

#module Search
#  def self.included(base)
#    base.class_eval do
#      is_indexed(:fields => [:name], 
#                 :include => [{:association_name => 'code_comment', :field => 'body', :as => :comment}],
#                 :conditions => "type = '#{base.tableize.singularize}'")
#    end
#  end
#end