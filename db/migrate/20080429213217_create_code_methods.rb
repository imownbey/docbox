class CreateCodeMethods < ActiveRecord::Migration
  def self.up
    create_table :code_methods do |t|
      t.integer :code_container_id, :code_file_id
      t.string :name
      t.string :parameters
      t.string :block_parameters
      t.boolean :singleton
      t.string :visibility, :length => 10
      t.boolean :force_documentation
      t.text :source_code

      t.datetime :created_at
    end
  end

  def self.down
    drop_table :code_methods
  end
end
