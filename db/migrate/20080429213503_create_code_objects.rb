class CreateCodeObjects < ActiveRecord::Migration
  def self.up
    create_table :code_objects do |t|
      t.integer :parent_id
      t.string :type
      t.string :name
      t.string :value
      t.integer :visibility
      t.string :read_write
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :code_objects
  end
end
