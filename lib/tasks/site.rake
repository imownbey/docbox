namespace :docbox do
  desc "Import"
  task :import => :environment do
    
    require 'rdoc/rdoc'
    require "#{File.dirname(__FILE__)}/../parsing"

    rdoc = RDoc::RDoc.new
    Dir.chdir("#{RAILS_ROOT}/code/")
    @files = Rake::FileList.new
   #   @files.include('railties/CHANGELOG')
   #   @files.include('railties/MIT-LICENSE')
   #   @files.include('railties/README')
   #   @files.include('railties/lib/{*.rb,commands/*.rb,rails/*.rb,rails_generator/*.rb}')
   #
   #   @files.include('activerecord/README')
   #   @files.include('activerecord/CHANGELOG')
   #   @files.include('activerecord/lib/active_record/**/*.rb')
   #   @files.exclude('activerecord/lib/active_record/vendor/*')
   #
   #   @files.include('activeresource/README')
   #   @files.include('activeresource/CHANGELOG')
   #   @files.include('activeresource/lib/active_resource.rb')
   #   @files.include('activeresource/lib/active_resource/*')
   #
   #   @files.include('actionpack/README')
   #   @files.include('actionpack/CHANGELOG')
   #   @files.include('actionpack/lib/action_controller/**/*.rb')
   #   @files.include('actionpack/lib/action_view/**/*.rb')
   #   @files.exclude('actionpack/lib/action_controller/vendor/*')
   #
   #   @files.include('actionmailer/README')
   #   @files.include('actionmailer/CHANGELOG')
   #   @files.include('actionmailer/lib/action_mailer/base.rb')
   #   @files.exclude('actionmailer/lib/action_mailer/vendor/*')
   #
      @files.include('activesupport/README')
      @files.include('activesupport/CHANGELOG')
      @files.include('activesupport/lib/active_support/**/*.rb')
      @files.exclude('activesupport/lib/active_support/vendor/*')
    rdoc.import!(@files)
  end

  task :export => :environment do
    raise "Id must be passed" unless ENV["ID"]
    raise "No such comment" unless comment = CodeComment.find(ENV["ID"])
    raise "Version must be passed" unless ENV["V"]
    comment.export! ENV["V"].to_i
  end
end