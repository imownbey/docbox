class CreateCodeContainers < ActiveRecord::Migration
  def self.up
    create_table :code_containers do |t|
      t.string :type
      t.integer :code_container_id, :code_file_id
      t.string :name
      t.string :full_name
      t.string :superclass
      t.string :line_code
      t.boolean :main_comment
      
      t.datetime :created_at
    end
    
    add_index :code_containers, :main_comment
  end

  def self.down
    drop_table :code_containers
  end
end
