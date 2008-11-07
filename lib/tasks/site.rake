class Rake::RDocTask
   def define
     task :rdoc do
       require 'rdoc/rdoc'
       require "#{File.dirname(__FILE__)}/../parsing"
       RDoc::RDoc.new.import!(rdoc_files.to_a)
     end
     self
   end
  
end

namespace :docbox do
  desc "Import"
  task :import => :environment do
   rake = Rake::Application.new
   chdir('code')
   Dir.glob("#{RAILS_ROOT}/code/**/{rakefile,Rakefile,rakefile.rb,Rakefile.rb,*.rake}").each do |f|
     Kernel.load(File.expand_path(f))
   end
   #rake.invoke_task('rdoc')
   Rake::Task['rdoc'].invoke
  end

  task :export => :environment do
    raise "Id must be passed" unless ENV["ID"]
    raise "No such comment" unless comment = CodeComment.find(ENV["ID"])
    raise "Version must be passed" unless ENV["V"]
    comment.export! ENV["V"].to_i
  end
end