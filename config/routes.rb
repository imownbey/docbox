ActionController::Routing::Routes.draw do |map|
  get = {:method => :get}
  put = {:method => :put}
  post = {:method => :post}

  map.resources :users

  map.resource :session
  
  map.with_options :controller => 'documentation', :path_prefix => 'docs', :conditions => get do |docs|
    docs.file_doc 'file/*path', :action => 'show_file'
    docs.docs '', :action => 'index'
    docs.doc '*tokens', :action => 'show'
  end
  
  map.with_options :controller => 'comments', :path_prefix => 'comments' do |comments|
    comments.comments '', :conditions => get
    map.formatted_comments 'comments.:format', :conditions => get, :controller => 'comments'
    
    comments.new_comment 'new/*tokens', :conditions => get,  :action => 'new'
    comments.connect 'new/*tokens',     :conditions => post, :action => 'create'
    
    comments.edit_comment ':id/edit',  :conditions => get, :action => 'edit'
    comments.connect ':id',            :conditions => put, :action => 'update'
    comments.connect ':id.:format',    :conditions => put, :action => 'update'
    
    comments.comment ':id', :conditions => get, :action => 'show'
  end
  
  
  map.with_options :controller => 'commentables', :path_prefix => 'commentables' do |commentables|
    commentables.commentable ':id', :conditions => get, :action => 'show'
  end

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
