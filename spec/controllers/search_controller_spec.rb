require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchController do

  it "should render index" do
    get :index
    
    response.should be_success
    response.should render_template('index')
  end
  
  it "should render results" do
    mock_search
    get :results, :q => 'hello'
    
    response.should be_success
    response.should render_template('results')
  end
  
  it "should interact with Sphinx" do
    mock_search
    
    get :results, :q => 'hello'
  end
  
  def mock_search
    my_mock = mock("search")
    my_mock.should_receive(:excerpt)
    Ultrasphinx::Search.stub!(:new).and_return my_mock
  end
end
