namespace :docbox do
  desc "Import"
  task :import => :environment do
    require 'rdoc/rdoc'
    require "#{File.dirname(__FILE__)}/../parsing"
    rdoc = RDoc::RDoc.new
    Dir.chdir("#{RAILS_ROOT}/code/")
    rdoc.import!(%W{.})
  end

  task :export => :environment do
    raise "Id must be passed" unless ENV["ID"]
    raise "No such comment" unless comment = CodeComment.find(ENV["ID"])
    raise "Version must be passed" unless ENV["V"]
    comment.export! ENV["V"].to_i
  end
end