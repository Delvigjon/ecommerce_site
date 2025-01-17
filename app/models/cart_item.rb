class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }

  # Méthode pour calculer le prix total de l'article
  def total_price
    product.price * quantity
  end
end
