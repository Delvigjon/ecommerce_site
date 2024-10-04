class HomeController < ApplicationController
  def index
    @products = Product.limit(6) # Charge les 6 produits les plus populaires (exemple)
  end
end
