# config/routes.rb

Rails.application.routes.draw do

  # =========================================================
  # AUTHENTIFICATION
  # =========================================================

  devise_for :users


  # =========================================================
  # INSCRIPTION PROFESSIONNELLE
  # =========================================================

  get "/inscription/pro",
      to: "business_registrations#new",
      as: :new_business_registration

  post "/inscription/pro",
       to: "business_registrations#create",
       as: :business_registration


  # =========================================================
  # HOME
  # =========================================================

  root "home#index"


  # =========================================================
  # BOUTIQUE
  # =========================================================

  resources :products,
            only: %i[
              index
              show
            ]

  resources :offers,
            only: %i[
              index
              show
            ]


  # =========================================================
  # PANIER
  # =========================================================

  resources :carts,
            only: %i[
              show
              update
            ] do

    resources :cart_items,
              only: %i[
                create
                update
                destroy
              ]

  end


  # =========================================================
  # COMMANDES CLIENT
  # =========================================================

  resources :orders,
            only: %i[
              new
              create
              show
              index
            ] do

    # -------------------------------------------------------
    # FACTURE PDF
    # -------------------------------------------------------

    member do
      get :invoice
    end

  end


  # =========================================================
  # CHECKOUT
  # =========================================================

  # ---------------------------------------------------------
  # PAGE PAYMENT ELEMENT
  # ---------------------------------------------------------

  get "/checkout/payment",
      to: "checkout#payment",
      as: :checkout_payment


  # ---------------------------------------------------------
  # CRÉATION PAYMENT INTENT STRIPE
  # ---------------------------------------------------------

  post "/checkout/payment_intent",
       to: "checkout#payment_intent",
       as: :checkout_payment_intent


  # ---------------------------------------------------------
  # ADRESSE DE LIVRAISON
  # ---------------------------------------------------------

  patch "/checkout/address",
        to: "checkout#update_address",
        as: :checkout_address


  # ---------------------------------------------------------
  # PAIEMENT CONFIRMÉ
  # ---------------------------------------------------------

  get "/checkout/success",
      to: "checkout#success",
      as: :checkout_success


  # ---------------------------------------------------------
  # PAIEMENT ANNULÉ
  # ---------------------------------------------------------

  get "/checkout/cancel",
      to: "checkout#cancel",
      as: :checkout_cancel


  # =========================================================
  # PAGES STATIQUES
  # =========================================================

  get "/contact",
      to: "pages#contact",
      as: :contact

  get "/about",
      to: "pages#about",
      as: :about


  # =========================================================
  # BACK-OFFICE
  # =========================================================

  namespace :backoffice do

    # -------------------------------------------------------
    # DASHBOARD
    # -------------------------------------------------------

    root "dashboard#index"


    # -------------------------------------------------------
    # PRODUITS
    # CRUD COMPLET
    # -------------------------------------------------------

    resources :products


    # -------------------------------------------------------
    # COMMANDES
    # -------------------------------------------------------

    resources :orders,
              only: %i[
                index
                show
                update
              ]


    # -------------------------------------------------------
    # CLIENTS
    # CRUD COMPLET
    # -------------------------------------------------------

    resources :users,
              only: %i[
                index
                show
                new
                create
                edit
                update
                destroy
              ]


    # -------------------------------------------------------
    # OFFRES
    # CRUD COMPLET
    # -------------------------------------------------------

    resources :offers

  end


  # =========================================================
  # HEALTH CHECK
  # =========================================================

  get "up" => "rails/health#show",
      as: :rails_health_check

end
