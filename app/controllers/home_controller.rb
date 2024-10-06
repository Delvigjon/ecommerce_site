class HomeController < ApplicationController
  def index
    @products = Product.limit(4) # Charge les 6 produits les plus populaires (exemple)
  end
end
