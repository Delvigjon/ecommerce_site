class OffersController < ApplicationController
  def index
    @offers = Offer
      .includes(:product) # évite des requêtes N+1 si tu affiches le produit lié
      .order(created_at: :desc)

    # Optionnel : limiter si tu veux une page courte
    # @offers = @offers.limit(24)
  end
end
