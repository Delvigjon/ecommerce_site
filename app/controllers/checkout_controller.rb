# app/controllers/checkout_controller.rb

class CheckoutController < ApplicationController
  before_action :authenticate_user!

  TVA_RATE = 0.20


  # =========================================================
  # PAGE PAIEMENT
  # =========================================================

  def payment
    @cart = current_user.cart

    if @cart.blank? || @cart.cart_items.empty?
      redirect_to products_path,
                  alert: "Votre panier est vide."
      return
    end

    @total_ttc =
      cart_total_ttc(@cart)

    @total_ht =
      (@total_ttc / (1 + TVA_RATE)).round(2)

    @tva_total =
      (@total_ttc - @total_ht).round(2)
  end


  # =========================================================
  # PAYMENT INTENT
  # Appelé par Stimulus au chargement de payment.html.erb
  # =========================================================

  def payment_intent
    cart =
      current_user.cart


    if cart.blank? || cart.cart_items.empty?
      render json: {
        error: "Votre panier est vide."
      }, status: :unprocessable_entity

      return
    end


    total_ttc =
      cart_total_ttc(cart)


    payment_intent =
      Stripe::PaymentIntent.create(

        amount:
          (total_ttc * 100).round,

        currency:
          "eur",

        automatic_payment_methods: {
          enabled: true
        },

        metadata: {
          user_id: current_user.id,
          cart_id: cart.id
        }
      )


    render json: {
      client_secret: payment_intent.client_secret
    }


  rescue Stripe::StripeError => e

    render json: {
      error: e.message
    }, status: :unprocessable_entity
  end


  # =========================================================
  # ADRESSE DE LIVRAISON
  # Enregistrée juste avant confirmation Stripe
  # =========================================================

  def update_address
    address =
      params[:address]
        .to_s
        .strip

    postal_code =
      params[:postal_code]
        .to_s
        .strip

    city =
      params[:city]
        .to_s
        .strip


    # -------------------------------------------------------
    # Validation
    # -------------------------------------------------------

    if address.blank? ||
       postal_code.blank? ||
       city.blank?

      render json: {
        error: "Veuillez renseigner votre adresse de livraison complète."
      }, status: :unprocessable_entity

      return
    end


    # -------------------------------------------------------
    # Sauvegarde sur le compte client
    # -------------------------------------------------------

    current_user.update!(
      address: address,
      postal_code: postal_code,
      city: city
    )


    render json: {
      success: true
    }


  rescue ActiveRecord::RecordInvalid => e

    render json: {
      error: e.record.errors.full_messages.to_sentence
    }, status: :unprocessable_entity
  end


  # =========================================================
  # SUCCESS
  # =========================================================

  def success
    payment_intent_id =
      params[:payment_intent]


    # -------------------------------------------------------
    # PaymentIntent présent ?
    # -------------------------------------------------------

    if payment_intent_id.blank?
      redirect_to root_path,
                  alert: "Paiement Stripe introuvable."
      return
    end


    # =======================================================
    # VÉRIFICATION STRIPE
    # =======================================================

    payment_intent =
      Stripe::PaymentIntent.retrieve(
        payment_intent_id
      )


    unless payment_intent.status == "succeeded"
      redirect_to checkout_payment_path,
                  alert: "Le paiement n'a pas été confirmé."
      return
    end


    # =======================================================
    # COMMANDE DÉJÀ CRÉÉE ?
    # =======================================================

    existing_order =
      Order.find_by(
        stripe_payment_intent_id:
          payment_intent.id
      )


    if existing_order.present?

      # Sécurité :
      # on vérifie que la commande appartient bien
      # au client actuellement connecté.

      unless existing_order.user_id == current_user.id
        redirect_to root_path,
                    alert: "Impossible d'accéder à cette commande."
        return
      end


      redirect_to order_path(existing_order),
                  notice: "Commande déjà enregistrée."

      return
    end


    # =======================================================
    # PANIER
    # =======================================================

    cart =
      current_user.cart


    if cart.blank? ||
       cart.cart_items.empty?

      redirect_to root_path,
                  notice: "Paiement confirmé."

      return
    end


    # =======================================================
    # VÉRIFICATION METADATA STRIPE
    # =======================================================

    metadata_user_id =
      payment_intent
        .metadata
        .user_id
        .to_s

    metadata_cart_id =
      payment_intent
        .metadata
        .cart_id
        .to_s


    if metadata_user_id != current_user.id.to_s ||
       metadata_cart_id != cart.id.to_s

      redirect_to root_path,
                  alert: "Impossible de valider cette commande."

      return
    end


    # =======================================================
    # ADRESSE DE LIVRAISON
    # =======================================================

    formatted_address = [
      current_user.address,
      current_user.postal_code,
      current_user.city
    ]
      .compact
      .reject(&:blank?)
      .join(", ")


    if formatted_address.blank?

      redirect_to checkout_payment_path,
                  alert: "Adresse de livraison manquante."

      return
    end


    # =======================================================
    # TOTAL COMMANDE
    # =======================================================

    total_ttc =
      cart_total_ttc(cart)


    # -------------------------------------------------------
    # Contrôle montant réellement payé chez Stripe
    # -------------------------------------------------------

    expected_amount =
      (total_ttc * 100).round


    if payment_intent.amount_received != expected_amount

      redirect_to root_path,
                  alert: "Le montant du paiement ne correspond pas à la commande."

      return
    end


    # =======================================================
    # CRÉATION COMMANDE
    # =======================================================

    order = nil


    ActiveRecord::Base.transaction do

      # -----------------------------------------------------
      # Order
      # -----------------------------------------------------

      order =
        current_user.orders.create!(
          status: "paid",
          total_price: total_ttc,
          address: formatted_address,
          stripe_payment_intent_id:
            payment_intent.id
        )


      # -----------------------------------------------------
      # Numéro de facture
      # -----------------------------------------------------

      order.ensure_invoice!


      # -----------------------------------------------------
      # OrderItems
      # -----------------------------------------------------

      cart.cart_items.includes(:product).each do |item|

        order.order_items.create!(

          product:
            item.product,

          quantity:
            item.quantity,

          # IMPORTANT :
          # price contient le prix TTC historique
          # au moment de la commande.
          price:
            normalized_price(
              item.product.price
            )
        )

      end


      # -----------------------------------------------------
      # Vider le panier
      #
      # Seulement lorsque :
      # - l'Order existe
      # - la facture est numérotée
      # - toutes les lignes sont créées
      # -----------------------------------------------------

      cart.cart_items.destroy_all
    end


    # =======================================================
    # REDIRECTION
    # =======================================================

    redirect_to order_path(order),
                notice: "Paiement confirmé, votre commande a bien été enregistrée."


  # =========================================================
  # STRIPE ERROR
  # =========================================================

  rescue Stripe::StripeError => e

    redirect_to root_path,
                alert: "Impossible de vérifier le paiement : #{e.message}"


  # =========================================================
  # ACTIVE RECORD ERROR
  # =========================================================

  rescue ActiveRecord::RecordInvalid => e

    redirect_to root_path,
                alert: "Impossible d'enregistrer la commande : #{e.record.errors.full_messages.to_sentence}"
  end


  # =========================================================
  # CANCEL
  # =========================================================

  def cancel
    redirect_to new_order_path,
                alert: "Le paiement a été annulé."
  end


  private


  # =========================================================
  # TOTAL TTC PANIER
  #
  # IMPORTANT :
  # product.price est un prix TTC.
  #
  # Exemple :
  #
  # Produit : 120 € TTC
  #
  # HT :
  # 120 / 1.20 = 100 €
  #
  # TVA :
  # 20 €
  #
  # Stripe reçoit :
  # 120 €
  # =========================================================

  def cart_total_ttc(cart)
    cart.cart_items.sum do |item|

      normalized_price(
        item.product.price
      ) * item.quantity

    end.round(2)
  end


  # =========================================================
  # NORMALISATION PRIX
  # =========================================================

  def normalized_price(value)
    value
      .to_s
      .tr(",", ".")
      .to_f
  end
end
