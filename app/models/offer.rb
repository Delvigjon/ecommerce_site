class Offer < ApplicationRecord
  belongs_to :user
  belongs_to :product
  
  validates :user, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def formatted_price
    "#{price} €"
  end

  def discount_price(discount_percentage)
    price - (price * discount_percentage / 100.0)
  end
end
