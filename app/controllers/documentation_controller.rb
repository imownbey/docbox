class DocumentationController < ApplicationController
  def index
    @classes = CodeContainer.not_file.find(:all)
    @files = CodeFile.find(:all)
    
    @main_object = CodeContainer.main_comment.first
  end
  
  def show
    @objects = get_object(params[:tokens])
    
    if @objects
      owner = @objects.last.try(:owner)
      @requested_object = (owner || @objects.last)
      @methods = {}
      
      if @requested_object.is_a?(CodeMethod)
        @in_file = @requested_object.code_file
        @versions = @requested_object.code_comment.versions
        render :template => 'documentation/show_method'
      else
        @methods[:all] = @requested_object.code_methods.with_comments.with_container.ordered
        @methods[:instance] = {}
        @methods[:instance][:all] = @methods[:all].select{ |m| m.singleton? }
        @methods[:instance] = seperate_methods(@methods[:instance][:all].dup)
      
        @methods[:class] = {}
        @methods[:class][:all] = @methods[:all] - @methods[:instance][:all]
        @methods[:class] = seperate_methods(@methods[:class][:all].dup)
        
        if (@requested_object.is_a?(CodeClass) || @requested_object.is_a?(CodeModule))
          @constants = @requested_object.code_constants
          @attributes = @requested_object.code_attributes
          @in_files = @requested_object.code_files.all
        end
      end
    else
      # 404
    end
  end
  
  def show_file
    path = params[:path].join('/')
    @file = CodeFile.find_by_full_name(path)
    @comment = @file.comment
    if @file
      # Render
    else
      render_404
    end
  end
  
  private
  
  def seperate_methods(methods)
    if methods.nil? || methods.empty?
      {
        :all => [],
        :private => [],
        :public => [],
        :protected => []
      }
    else
      {
        :all => methods,
        :private => methods.select{ |m| m.private? },
        :public =>  methods.select{ |m| m.public? },
        :protected =>  methods.select{ |m| m.protected? }
      }
    end
  end
end
