class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.text :body
      t.integer :owner_id, :user_id
      t.string :owner_type
      t.boolean :exported
      t.integer :version, :default => 1
      t.string :commit, :length => 40

      t.datetime :created_at
    end
  end

  def self.down
    drop_table :comments
  end
end
