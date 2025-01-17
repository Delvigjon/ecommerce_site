class CartItemsController < ApplicationController
  before_action :set_cart
  before_action :set_cart_item, only: [:update, :destroy]

  # Ajoute un produit au panier
  def create
    product = Product.find(params[:product_id])
    existing_item = @cart.cart_items.find_by(product_id: product.id)

    if existing_item
      existing_item.increment!(:quantity, params[:quantity].to_i)
    else
      @cart.cart_items.create!(product: product, quantity: params[:quantity].to_i)
    end

    redirect_to cart_path(@cart), notice: 'Produit ajouté au panier.'
  end

  # Met à jour la quantité d'un produit dans le panier
  def update
    new_quantity = params[:quantity].to_i

    if new_quantity <= @cart_item.product.stock && new_quantity > 0
      @cart_item.update!(quantity: new_quantity)
      redirect_to cart_path(@cart), notice: "Quantité mise à jour."
    else
      redirect_to cart_path(@cart), alert: "Quantité invalide ou stock insuffisant."
    end
  end

  private

  def set_cart
    @cart = current_user.cart || current_user.create_cart
  end

  def set_cart_item
    @cart_item = @cart.cart_items.find(params[:id])
  end
end
