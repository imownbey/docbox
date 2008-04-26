require 'rdoc/rdoc'

# FIXME: This is a hack
RDoc::RDoc.class_eval %{
  GENERATORS['html'] = Generator.new("#{File.expand_path(File.dirname(__FILE__))}/sql_generator.rb", 'SqlGenerator', 'sql')
}

rdoc = RDoc::RDoc.new

rdoc.document(%W{--one-file #{File.expand_path(File.dirname(__FILE__))}/../authenticated_system.rb})
