# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require 'git'
require 'lib/core_ext'

require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

require 'lib/markup'

Rails::Initializer.run do |config|
  config.gem 'syntax'
  config.gem 'syntaxi'
  
  config.action_controller.session = {
    :session_key => '_docbox_session',
    :secret      => 'b08a5ac6283b6da0da84c9f56871c421b80a42f208bf13681218fc848c3881eb6261fa5b87deffb3958a9114ad1509b5e171adcddd0d2bc2bbc8750cacf0a984'
  }

  config.load_paths += %W[
    #{RAILS_ROOT}/app/models/code_objects
    #{RAILS_ROOT}/app/models/code_containers
  ] 
end