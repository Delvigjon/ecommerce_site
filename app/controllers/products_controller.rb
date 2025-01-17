class ProductsController < ApplicationController
  before_action :set_cart, only: [:show]

  def show
    @product = Product.find(params[:id])
  end

  private

  def set_cart
    if current_user
      @cart = current_user.cart || current_user.create_cart
    else
      redirect_to new_user_session_path, alert: "Vous devez être connecté pour accéder au panier."
    end
  end
  
end
