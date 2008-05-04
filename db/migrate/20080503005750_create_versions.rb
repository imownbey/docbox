class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.text :comment
      t.integer :version
      t.integer :user_id
      t.boolean :exported
      t.integer :container_id

      t.timestamps
    end
  end

  def self.down
    drop_table :versions
  end
end
