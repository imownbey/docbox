class SearchController < ApplicationController
  def index
    respond_to do |format|
      format.html
    end
  end
  
  def results
    redirect_to :action => :index if params[:q].blank?
    
    @search = Ultrasphinx::Search.new(:query => params[:q])
    Ultrasphinx::Search.excerpting_options[:limit] = 60
    @search.excerpt
    respond_to do |format|
      format.html
      format.js do
        @search.run
        render :partial => 'search_sidebar', :locals => {:query => params[:q], :results => @search}
      end
    end
  end
end
