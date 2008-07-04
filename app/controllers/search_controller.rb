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
  end
end
