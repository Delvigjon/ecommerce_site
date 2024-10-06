class OffersController < ApplicationController
  def index
    # Récupérer les offres ou ajouter la logique nécessaire
    @offers = Offer.all # Si vous avez un modèle Offer
  end
end
