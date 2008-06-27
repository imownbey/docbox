class CreateCodeComments < ActiveRecord::Migration
  def self.up
    create_table :code_comments do |t|
      t.text :body, :raw_body
      t.integer :owner_id, :user_id
      t.string :owner_type
      t.boolean :exported, :uses_begin, :skip, :default => false
      t.integer :version, :default => 1
      t.string :commit, :length => 40

      t.datetime :created_at
    end
  end

  def self.down
    drop_table :comments
  end
end
