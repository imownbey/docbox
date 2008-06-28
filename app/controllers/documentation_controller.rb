class DocumentationController < ApplicationController
  def index
    @classes = CodeContainer.not_file.find(:all)
  end
  
  def show
    @objects = get_object(params[:tokens])
    
    if @objects
      owner = @objects.last.try(:owner)
      @containing_class = (owner || @objects.last)
      @methods = {}
      @methods[:all] = @containing_class.code_methods.with_comments.ordered
      @methods[:instance] = {}
      @methods[:instance][:all] = @methods[:all].select{ |m| m.singleton? }
      @methods[:instance] = seperate_methods(@methods[:instance][:all].dup)
      
      @methods[:class] = {}
      @methods[:class][:all] = @methods[:all] - @methods[:instance][:all]
      @methods[:class] = seperate_methods(@methods[:class][:all].dup)
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
  
  def get_object(params)
    objects = []
    params.each_with_index do |token, index|
      objects[index] = find_token token, (objects[index - 1] || nil), (params.length == index + 1)
    end
    objects
  end

  def find_token(token, parent, last = false)
    if last
      conditions = {:include => [:code_methods]}
    else
      conditions = {}
    end
    
    if parent
      parent.code_methods.find_by_name(token, conditions) || parent.code_objects.find_by_name(token, conditions) || parent.code_containers.find_by_name(token, conditions)
    else
      CodeContainer.find_by_name(token, conditions)
    end
  end
  
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
