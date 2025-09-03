class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :category
      t.string :size
      t.string :color
      t.decimal :price
      t.string :image_url
      t.text :tags

      t.timestamps
    end
  end
end
