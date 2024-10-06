class CreateSpecialOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :special_offers do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :image_url

      t.timestamps
    end
  end
end
