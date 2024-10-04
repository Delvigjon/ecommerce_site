Rails.application.routes.draw do
  devise_for :users

  # Route pour la page d'accueil
  root "home#index"

  # Routes pour les produits
  resources :products, only: [:index, :show]
  resources :offers, only: [:index]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
