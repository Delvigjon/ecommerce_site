class ProductsController < ApplicationController
  # Affiche tous les produits
  def index
    @products = Product.all
  end

  # Affiche les détails d'un produit
  def show
    @product = Product.find(params[:id])
  end
end
