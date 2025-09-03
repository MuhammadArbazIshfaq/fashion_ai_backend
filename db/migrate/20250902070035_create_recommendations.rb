class CreateRecommendations < ActiveRecord::Migration[8.0]
  def change
    create_table :recommendations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :score
      t.text :reason
      t.string :selfie_url
      t.json :analysis_json
      t.string :preview_url

      t.timestamps
    end
  end
end
