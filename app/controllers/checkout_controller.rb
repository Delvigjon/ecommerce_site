class CheckoutController < ApplicationController
  before_action :authenticate_user!

  TVA_RATE = 0.20

  def create
    cart = current_user.cart

    if cart.blank? || cart.cart_items.empty?
      redirect_to products_path, alert: "Votre panier est vide."
      return
    end

    session = Stripe::Checkout::Session.create(
      mode: "payment",
      client_reference_id: "#{current_user.id}-#{cart.id}",

      line_items: cart.cart_items.map do |item|
        price_ht  = normalized_price(item.product.price)
        price_ttc = (price_ht * (1 + TVA_RATE)).round(2)

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
      redirect_to order_path(existing_order), notice: "Commande déjà enregistrée."
      return
    end

    formatted_address = [
      current_user.address,
      current_user.postal_code,
      current_user.city
    ].compact.reject(&:blank?).join(", ")

    total_ht = cart.cart_items.sum do |item|
      normalized_price(item.product.price) * item.quantity
    end

    total_ttc = (total_ht * (1 + TVA_RATE)).round(2)

    order = current_user.orders.create!(
      status: "paid",
      total_price: total_ttc,
      address: formatted_address.presence || "Adresse non renseignée",
      stripe_session_id: stripe_session.id
    )

    cart.cart_items.find_each do |item|
      order.order_items.create!(
        product: item.product,
        quantity: item.quantity,
        price: normalized_price(item.product.price)
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

  private

  def normalized_price(value)
    value.to_s.tr(",", ".").to_f
  end
end
