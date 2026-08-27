class Order < ApplicationRecord
  belongs_to :user

  has_many :order_items,
           dependent: :destroy

  validates :stripe_payment_intent_id,
            uniqueness: true,
            allow_nil: true

  validates :invoice_number,
            uniqueness: true,
            allow_nil: true

  validates :status,
            presence: true

  # =========================================================
  # TOTAL
  # =========================================================

  def calculate_total_price
    order_items.sum do |item|
      item.total_price
    end
  end


  # =========================================================
  # FACTURE
  # =========================================================

  def ensure_invoice!
    return if invoice_number.present?

    update!(
      invoice_number: generated_invoice_number,
      invoiced_at: Time.current
    )
  end


  def generated_invoice_number
    year =
      (created_at || Time.current).year

    "FAC-#{year}-#{id.to_s.rjust(6, "0")}"
  end


  # =========================================================
  # STATUS
  # =========================================================

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
    when "completed"
      "Terminée"
    when "cancelled"
      "Annulée"
    else
      status.to_s.humanize
    end
  end
end
