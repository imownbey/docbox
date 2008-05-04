class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.text :body
      t.string :version, :length => 40
      t.integer :user_id
      t.boolean :exported, :default => false
      t.integer :comment_id

      t.datetime :created_at
    end
  end

  def self.down
    drop_table :versions
  end
end
