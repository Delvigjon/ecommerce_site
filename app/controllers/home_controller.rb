class HomeController < ApplicationController
  def index
    @products = Product.limit(6)
    @offers = Offer.limit(3)
  end
end
