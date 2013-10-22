class CreateLinks < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.integer :from_id
      t.integer :to_id

      t.timestamps
    end
    add_index :links, [:from_id, :to_id]
  end
end
