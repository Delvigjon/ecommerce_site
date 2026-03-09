class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :stripe_session_id, uniqueness: true, allow_nil: true
  validates :status, presence: true

  def calculate_total_price
    order_items.sum { |item| item.total_price }
  end

  def human_status
    case status
    when "pending"
      "En attente"
    when "paid"
      "Payée"
    when "processing"
      "En préparation"
    when "shipped"
      "Expédiée"
    when "delivered"
      "Livrée"
    when "cancelled"
      "Annulée"
    else
      status
    end
  end
end
