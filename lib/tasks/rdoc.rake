desc "Import"
task :import => :environment do
  require 'rdoc/rdoc'
  require "#{File.dirname(__FILE__)}/../parsing"
  rdoc = RDoc::RDoc.new
  rdoc.import!(%W{#{File.expand_path(File.dirname(__FILE__))}/../1.rb #{File.expand_path(File.dirname(__FILE__))}/../2.rb})
end

task :export => :environment do
  raise "Id must be passed" unless ENV["id"]
  raise "No such comment" unless comment = Comment.find(ENV["id"])
  
    
end