class Backoffice::OffersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_offer,
                only: %i[
                  show
                  edit
                  update
                  destroy
                ]

  def index
    @offers =
      Offer
        .includes(:product, :user)
        .order(created_at: :desc)
  end

  def show
  end

  def new
    @offer =
      Offer.new(
        user: current_user
      )
  end

  def create
    @offer =
      Offer.new(offer_params)

    @offer.user ||=
      current_user

    if @offer.save
      redirect_to(
        backoffice_offer_path(@offer),
        notice: "L'offre a bien été créée."
      )
    else
      render :new,
             status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @offer.update(offer_params)
      redirect_to(
        backoffice_offer_path(@offer),
        notice: "L'offre a bien été mise à jour."
      )
    else
      render :edit,
             status: :unprocessable_entity
    end
  end

  def destroy
    @offer.destroy!

    redirect_to(
      backoffice_offers_path,
      notice: "L'offre a bien été supprimée."
    )
  end

  private

  def set_offer
    @offer =
      Offer
        .includes(:product, :user)
        .find(params[:id])
  end

  def offer_params
    params
      .require(:offer)
      .permit(
        :name,
        :description,
        :price,
        :image_url,
        :product_id,
        :user_id
      )
  end

  def require_admin!
    return if current_user&.role == "admin"

    redirect_to(
      root_path,
      alert: "Accès non autorisé."
    )
  end
end
