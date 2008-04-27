module RDoc
  class RDoc
    def generate_sql(argv)
      TopLevel::reset

      @stats = Stats.new

      options = Options.instance
      options.parse(argv, GENERATORS)

      @last_created = nil
      start_time = Time.now

      file_info = parse_files(options)

      if file_info.empty?
        return false
      else
        $stderr.puts "\nGenerating SQL..."

        require "#{File.expand_path(File.dirname(__FILE__))}/../parsing/sql_generator"

        gen = Generators::SqlGenerator.new(options)
        begin
          sql = gen.generate(file_info)
        ensure
          Dir.chdir(pwd)
        end
        sql
      end
    end
  end
end
  desc "Import"
  task :import do
    require 'rdoc/rdoc'
    rdoc = RDoc::RDoc.new
    puts rdoc.generate_sql(%W{#{File.expand_path(File.dirname(__FILE__))}/../authenticated_system.rb})
  end