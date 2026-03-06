class CheckoutController < ApplicationController
  before_action :authenticate_user!

def create
  cart = current_user.cart

  if cart.blank? || cart.cart_items.empty?
    redirect_to products_path, alert: "Votre panier est vide."
    return
  end

  tva_rate = 0.20

  session = Stripe::Checkout::Session.create(
    mode: "payment",
    client_reference_id: "#{current_user.id}-#{cart.id}",

    line_items: cart.cart_items.map do |item|
      price_ht  = item.product.price.to_f
      price_ttc = price_ht * (1 + tva_rate)

      product_description = item.product.description.to_s.strip
      product_description = "Prix TTC (TVA 20 % incluse)" if product_description.blank?

      product_data = {
        name: item.product.name,
        description: product_description,
        images: item.product.image_url.present? ? [item.product.image_url] : []
      }

      {
        quantity: item.quantity,
        price_data: {
          currency: "eur",
          unit_amount: (price_ttc * 100).round,
          product_data: product_data
        }
      }
    end,

    success_url: checkout_success_url + "?session_id={CHECKOUT_SESSION_ID}",
    cancel_url: checkout_cancel_url
  )

  redirect_to session.url, allow_other_host: true

rescue Stripe::StripeError => e
  redirect_to new_order_path, alert: "Erreur Stripe : #{e.message}"
end

  def success
  session_id = params[:session_id]

  if session_id.blank?
    redirect_to root_path, alert: "Session Stripe introuvable."
    return
  end

  stripe_session = Stripe::Checkout::Session.retrieve(session_id)
  cart = current_user.cart

  if stripe_session.payment_status != "paid"
    redirect_to new_order_path, alert: "Le paiement n'a pas été confirmé."
    return
  end

  if cart.blank? || cart.cart_items.empty?
    redirect_to root_path, notice: "Paiement confirmé."
    return
  end

  existing_order = Order.find_by(stripe_session_id: stripe_session.id)

  if existing_order.present?
    redirect_to order_path(existing_order), notice: "Commande déjà confirmée."
    return
  end

  customer_address = stripe_session.customer_details&.address

  formatted_address =
    if customer_address.present?
      [
        customer_address.line1,
        customer_address.line2,
        customer_address.postal_code,
        customer_address.city,
        customer_address.state,
        customer_address.country
      ].compact.reject(&:blank?).join(", ")
    end

  order = current_user.orders.create!(
    status: "completed",
    total_price: cart.cart_items.sum(&:total_price),
    address: formatted_address.presence || "Adresse transmise via Stripe",
    stripe_session_id: stripe_session.id
  )

  cart.cart_items.find_each do |item|
    order.order_items.create!(
      product: item.product,
      quantity: item.quantity,
      price: item.product.price
    )
  end

  cart.cart_items.destroy_all

  redirect_to order_path(order), notice: "Paiement confirmé, votre commande a bien été enregistrée."
rescue Stripe::StripeError => e
  redirect_to root_path, alert: "Impossible de vérifier le paiement : #{e.message}"
end

  def cancel
    redirect_to new_order_path, alert: "Le paiement a été annulé."
  end
end
