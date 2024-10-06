class AddProductToOffers < ActiveRecord::Migration[7.1]
  def change
    add_reference :offers, :product, null: false, foreign_key: true
  end
end
