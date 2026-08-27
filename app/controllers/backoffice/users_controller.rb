# app/controllers/backoffice/users_controller.rb

class Backoffice::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user,
                only: %i[
                  show
                  edit
                  update
                  destroy
                ]


  # =========================================================
  # INDEX
  # =========================================================

  def index
    @users =
      User
        .includes(:orders)
        .order(created_at: :desc)
  end


  # =========================================================
  # SHOW
  # =========================================================

  def show
    @orders =
      @user
        .orders
        .includes(order_items: :product)
        .order(created_at: :desc)
  end


  # =========================================================
  # NEW
  # =========================================================

  def new
    @user =
      User.new(
        account_type: "individual",
        role: "customer"
      )
  end


  # =========================================================
  # CREATE
  # =========================================================

  def create
    @user =
      User.new(user_create_params)

    @user.role =
      "customer" if @user.role.blank?

    @user.account_type =
      "individual" if @user.account_type.blank?


    if @user.save

      redirect_to(
        backoffice_user_path(@user),
        notice: "Le client a bien été créé."
      )

    else

      flash.now[:alert] =
        "Certaines informations doivent être corrigées."

      render :new,
             status: :unprocessable_entity

    end
  end


  # =========================================================
  # EDIT
  # =========================================================

  def edit
  end


  # =========================================================
  # UPDATE
  # =========================================================

  def update
    attributes =
      user_update_params.to_h

    # -------------------------------------------------------
    # PASSWORD
    #
    # Si aucun mot de passe n'est renseigné dans le BO,
    # on ne modifie pas le mot de passe existant.
    # -------------------------------------------------------

    if attributes["password"].blank?
      attributes.delete("password")
      attributes.delete("password_confirmation")
    end


    if @user.update(attributes)

      redirect_to(
        backoffice_user_path(@user),
        notice: "Le client a bien été mis à jour."
      )

    else

      flash.now[:alert] =
        "Certaines informations doivent être corrigées."

      render :edit,
             status: :unprocessable_entity

    end
  end


  # =========================================================
  # DESTROY
  # =========================================================

  def destroy
    if @user == current_user

      redirect_to(
        backoffice_users_path,
        alert: "Vous ne pouvez pas supprimer votre propre compte administrateur."
      )

      return
    end


    @user.destroy!


    redirect_to(
      backoffice_users_path,
      notice: "Le compte client a bien été supprimé."
    )

  rescue ActiveRecord::RecordNotDestroyed => e

    redirect_to(
      backoffice_users_path,
      alert: "Impossible de supprimer ce client : #{e.record.errors.full_messages.to_sentence}"
    )
  end


  private


  # =========================================================
  # USER
  # =========================================================

  def set_user
    @user =
      User
        .includes(:orders)
        .find(params[:id])
  end


  # =========================================================
  # PARAMS — CREATE
  # =========================================================

  def user_create_params
    params
      .require(:user)
      .permit(
        :first_name,
        :last_name,
        :email,
        :phone,
        :account_type,
        :company_name,
        :siret,
        :address,
        :postal_code,
        :city,
        :role,
        :password,
        :password_confirmation
      )
  end


  # =========================================================
  # PARAMS — UPDATE
  # =========================================================

  def user_update_params
    params
      .require(:user)
      .permit(
        :first_name,
        :last_name,
        :email,
        :phone,
        :account_type,
        :company_name,
        :siret,
        :address,
        :postal_code,
        :city,
        :role,
        :password,
        :password_confirmation
      )
  end


  # =========================================================
  # ADMIN SECURITY
  # =========================================================

  def require_admin!
    return if current_user&.role == "admin"

    redirect_to(
      root_path,
      alert: "Accès non autorisé."
    )
  end
end
