class CreateUrls < ActiveRecord::Migration
  def change
    create_table :urls do |t|
      t.string :url
      t.integer :is_indexed, :default => 0

      t.timestamps
    end
  end
end
