class CreateErrors < ActiveRecord::Migration
  def self.up
    create_table :errors do |t|
      t.string :name
      t.string :pre_version_body
      t.string :version_body
      t.string :type
      t.string :message
      t.boolean :fixed, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :errors
  end
end
