class CreateContainers < ActiveRecord::Migration
  def self.up
    create_table :containers do |t|
      t.string :type
      t.integer :parent_id
      t.string :name
      t.string :full_name
      t.string :superclass
      t.string :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :containers
  end
end
