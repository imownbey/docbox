require 'rdoc/rdoc'

RDoc::RDoc.class_eval %{
  GENERATORS['html'] = Generator.new("#{File.dirname(__FILE__)}/sql_generator.rb", 'SqlGenerator', 'sql')
}

rdoc = RDoc::RDoc.new

rdoc.document(%W{--template=sql --one-file ../authenticated_system.rb})
