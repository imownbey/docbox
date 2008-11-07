class CreateChanges < ActiveRecord::Migration
  def self.up
    create_table :changes do |t|
      t.string :type
      t.integer :tag_id
      t.integer :owner_id
      t.string :owner_type

      t.timestamps
    end
  end

  def self.down
    drop_table :changes
  end
end
