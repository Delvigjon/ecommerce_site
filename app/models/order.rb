class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :status, presence: true

  def calculate_total_price
    order_items.sum { |item| item.total_price }
  end
end
