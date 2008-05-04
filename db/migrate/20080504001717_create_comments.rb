class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.text :body
      t.integer :owner_id
      t.string :owner_type
      t.boolean :exported

      t.datetime :created_at
    end
  end

  def self.down
    drop_table :comments
  end
end
