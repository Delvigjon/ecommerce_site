class RenameStripeSessionIdOnOrders < ActiveRecord::Migration[7.1]
  def change
    rename_column :orders,
                  :stripe_session_id,
                  :stripe_payment_intent_id
  end
end
