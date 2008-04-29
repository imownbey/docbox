
  desc "Import"
  task :import do
    require 'rdoc/rdoc'
    rdoc = RDoc::RDoc.new
    puts rdoc.generate_sql(%W{#{File.expand_path(File.dirname(__FILE__))}/../authenticated_system.rb})
  end