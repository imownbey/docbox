require 'rubygems'
require 'fileutils'
require 'highline'

include FileUtils

task :setup => :environment do
  begin
  settings = {}
  HighLine.color_scheme = HighLine::ColorScheme.new do |cs|
         cs[:headline]        = [ :bold, :magenta, :on_black ]
         cs[:strong]          = [ :bold, :green ]
         cs[:error]           = [ :bold, :red ]

       end
       
  h = HighLine.new
  h.wrap_at = 60
  
  h.say h.color("\nDOCBOX SETUP\n", :headline)
  
  
  h.say <<-EOC
  Docbox will now ask you a couple questions about your preffered setup. After asking you the questions, Docbox will pull the git repo which you specify into #{h.color "#{RAILS_ROOT}/code", :strong}. DocBox will then import the documentation for this code into the database.

EOC
  
  if File.exists?("#{RAILS_ROOT}/config/docbox.yml")
    h.say h.color("Error!", :error)
    h.say "It appears #{RAILS_ROOT}/config/docbox.yml already exists. Either move or delete this file, then re-run setup."
    exit
  end
  
  if File.exists?(RAILS_ROOT + '/code')
    if h.agree("It appears that #{RAILS_ROOT}/code already exists, do you want me to delete it now? (y,n)  ")
      rm_rf("#{RAILS_ROOT}/code")
      h.say("#{RAILS_ROOT}/code removed.")
    else
      h.say("This task is made to be ran with a clean slate. Please remove /code and rerun migrations before running.")
    end
  end
  settings["site_name"] = h.ask("Site name?  ")
  
  git = settings["git_url"] = h.ask("Git repo url?  ") {|q| q.validate = /.+/ }
  
  $stdout.print("Cloning git repo #{git} to /code... ")
  $stdout.flush
  `git clone #{git} code`
  cd('code')
  puts "Done"
  
  catch :end_branch do
    loop do
      settings["branch"] = h.ask("Git branch to store docs on?  ") { |q| q.default = "docs"}
      if `git ls-remote origin` =~ Regexp.new(settings["branch"])
        if h.agree "It appears that the branch #{settings["branch"]} already exists on remote 'origin'. Do you want to use the contents of this remote branch for your Docbox? (y,n)  "
          $stdout.print "Creating branch #{settings["branch"]} to track origin/#{settings["branch"]}... "
          $stdout.flush
          `git branch --track #{settings["branch"]} refs/remotes/origin/#{settings["branch"]}`
          `git checkout #{settings["branch"]}`
          puts "Done"
          throw :end_branch
        else
          # Loop runs again
        end
      else
        # Create the branch
        `git branch #{settings["branch"]}`
        `git checkout #{settings["branch"]}`
        throw :end_branch
      end
    end
  end
  settings["wrap_number"] = h.ask("How many charecters do you want the generated code comments to wrap at?  ", Integer) {|q| q.default = 80}
  settings["auto_push"] = h.agree("Do you want docbox to automatically push new commits that it makes to the remote origin?  (y,n) ")
  
  $stdout.print "Writting #{RAILS_ROOT}/config/docbox.yml... "
  $stdout.flush
  
  file = File.new("#{RAILS_ROOT}/config/docbox.yml", "w")
  file.puts(settings.to_yaml)
  puts "Done"
  
  user = {:admin => true}
  user[:login] = h.ask("Admin login?  ")
  user[:email] = h.ask("Admin email?  ")
  user[:password] = h.ask("Admin user password?  ") {|q| q.echo = "X" }
  user[:password_confirmation] = h.ask("Again?  ") {|q| q.echo = "X" }
  if User.create(user)
    h.say "Admin user #{user[:login]} created."
  else
    h.say h.color("Woops. Something went wrong created the admin user.", :error)
    exit
  end
  
  
  if h.agree("Do you want to import docs now?  (y,n) ")
    $stdout.print "Importing docs... "
    $stdout.flush
    Rake::Task["docbox:import"].invoke
    puts "Done"
  end
  ensure
  cd(RAILS_ROOT)
  end
end