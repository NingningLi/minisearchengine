class CreateWordLocations < ActiveRecord::Migration
  def change
    create_table :word_locations do |t|
      t.integer :url_id
      t.integer :word_id
      t.integer :location

      t.timestamps
    end
    add_index :word_locations, [:url_id, :word_id]
  end
end
