class CreateMeths < ActiveRecord::Migration
  def self.up
    create_table :meths do |t|
      t.integer :container_id
      t.string :name
      t.string :parameters
      t.string :block_parameters
      t.boolean :singleton
      t.string :visibility, :length => 10
      t.boolean :force_documentation
      t.text :comment
      t.text :source_code

      t.timestamps
    end
  end

  def self.down
    drop_table :meths
  end
end
