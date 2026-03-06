Rails.application.routes.draw do
  devise_for :users

  # Route pour la page d'accueil
  root "home#index"

  # Routes pour les paniers
  resources :carts, only: [:show, :update] do
    resources :cart_items, only: [:create, :update, :destroy]
  end

  post "/checkout/create", to: "checkout#create", as: :create_checkout
  get "/checkout/success", to: "checkout#success", as: :checkout_success
  get "/checkout/cancel", to: "checkout#cancel", as: :checkout_cancel
  # Routes pour les commandes
  resources :orders, only: [:new, :create, :show, :index]

  # Routes pour les produits et les offres
  resources :products, only: [:index, :show]
  resources :offers, only: [:index, :show]

  # Pages statiques
  get 'contact', to: 'pages#contact'
  get 'about', to: 'pages#about'

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
