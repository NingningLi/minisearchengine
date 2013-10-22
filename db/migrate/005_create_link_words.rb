class CreateLinkWords < ActiveRecord::Migration
  def change
    create_table :link_words do |t|
      t.integer :word_id
      t.integer :link_id

      t.timestamps
    end   
  end
end
