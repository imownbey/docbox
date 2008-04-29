desc "Import"
task :import => :environment do
  require 'rdoc/rdoc'
  require "#{File.dirname(__FILE__)}/../parsing/rdoc_ext"
  rdoc = RDoc::RDoc.new
  rdoc.import!(%W{#{File.expand_path(File.dirname(__FILE__))}/../authenticated_system.rb})
end