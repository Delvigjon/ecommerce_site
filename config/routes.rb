Rails.application.routes.draw do
  get 'products/index'
  get 'products/show'
  get 'offers/index'
  devise_for :users

  # Route pour la page d'accueil
  root "home#index"

  # Routes pour les produits
  resources :products, only: [:index, :show]
  resources :offers, only: [:index, :show]
   get 'contact', to: 'pages#contact'
  get 'about', to: 'pages#about'
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
