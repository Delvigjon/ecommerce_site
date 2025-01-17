class CartsController < ApplicationController
  before_action :set_cart

  # Affiche le panier
  def show
    @cart_items = @cart.cart_items.includes(:product)
  end

  # Met à jour le panier (par exemple, vider le panier)
  def update
    # Exemple d'action de mise à jour pour le panier (facultatif selon ton projet)
    if params[:clear_cart]
      @cart.cart_items.destroy_all
      redirect_to cart_path(@cart), notice: "Votre panier a été vidé."
    else
      redirect_to cart_path(@cart), alert: "Action inconnue."
    end
  end

  private

  def set_cart
    @cart = current_user.cart || current_user.create_cart
  end
end
