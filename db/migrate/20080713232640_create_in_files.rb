class CreateInFiles < ActiveRecord::Migration
  def self.up
    create_table :in_files do |t|
      t.references :code_container
      t.references :code_file
    end
  end

  def self.down
    drop_table :in_files
  end
end
