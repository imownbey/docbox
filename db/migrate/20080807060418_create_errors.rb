class CreateErrors < ActiveRecord::Migration
  def self.up
    create_table :errors do |t|
      t.integer :pre_version_id
      t.integer :version_id
      t.string :type
      t.string :message

      t.timestamps
    end
  end

  def self.down
    drop_table :errors
  end
end
