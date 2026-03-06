class ProductsController < ApplicationController
  before_action :set_cart, only: [:show]

  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])

    @related_products = Product
      .where.not(id: @product.id)
      .where.not(image_url: [nil, ""])
      .limit(4)
  end

  private

  def set_cart
    return unless current_user

    @cart = current_user.cart || current_user.create_cart
  end
end
