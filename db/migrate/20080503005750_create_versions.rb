class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.text :body
      t.string :commit, :length => 40
      t.integer :user_id, :code_comment_id, :version
      t.boolean :exported, :uses_begin, :skip, :default => false

      t.datetime :created_at
    end
  end

  def self.down
    drop_table :versions
  end
end
