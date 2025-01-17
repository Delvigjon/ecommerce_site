class OrdersController < ApplicationController
  before_action :set_order, only: [:show]
  before_action :set_cart, only: [:new, :create]

  def new
    @order = Order.new
  end

  def create
    @order = current_user.orders.new(order_params)
    @order.status = 'pending'
    @order.total_price = calculate_cart_total

    Rails.logger.debug("Paramètres de la commande : #{order_params.inspect}")
    Rails.logger.debug("Total calculé : #{@order.total_price}")

    if stock_available? && @order.save
      if save_order_items
        current_user.cart.cart_items.destroy_all
        redirect_to order_path(@order), notice: 'Commande créée avec succès.'
      else
        Rails.logger.debug("Échec de la sauvegarde des articles de commande")
        @order.destroy
        flash.now[:alert] = 'Erreur lors de la sauvegarde des articles de la commande.'
        render :new
      end
    else
      Rails.logger.debug("Erreurs de validation de la commande : #{@order.errors.full_messages}")
      flash.now[:alert] = 'Erreur lors de la création de la commande. Vérifiez les informations saisies.'
      render :new
    end
  end

  def show
  end

  def index
    @orders = current_user.orders
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end

  def set_cart
    @cart = current_user.cart
    unless @cart&.cart_items.any?
      redirect_to products_path, alert: 'Votre panier est vide. Ajoutez des articles avant de passer une commande.'
    end
  end

  def order_params
    params.require(:order).permit(:status, :address)
  end

  def calculate_cart_total
    @cart.cart_items.sum { |item| item.quantity * item.product.price }
  end

  def save_order_items
    success = true
    @cart.cart_items.each do |item|
      begin
        @order.order_items.create!(
          product: item.product,
          quantity: item.quantity,
          price: item.product.price
        )
        item.product.update!(stock: item.product.stock - item.quantity)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug("Erreur lors de la sauvegarde d'un article de commande : #{e.message}")
        success = false
        break
      end
    end
    success
  end

  def stock_available?
    stock_ok = true
    @cart.cart_items.each do |item|
      if item.quantity > item.product.stock
        Rails.logger.debug("Stock insuffisant pour le produit #{item.product.name}")
        @order.errors.add(:base, "Le produit #{item.product.name} n'a pas assez de stock (disponible : #{item.product.stock}, demandé : #{item.quantity}).")
        stock_ok = false
      end
    end
    stock_ok
  end
  
end
