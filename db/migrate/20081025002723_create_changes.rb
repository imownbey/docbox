class CreateChanges < ActiveRecord::Migration
  def self.up
    create_table :changes do |t|
      t.integer :owner_id,    :change_id
      t.string  :owner_type,  :change_type
      
      # Tagging
      # t.integer :tag_id
      
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :changes
  end
end
