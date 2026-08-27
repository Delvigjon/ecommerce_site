class BusinessRegistrationsController < ApplicationController
  def new
    @user = User.new(account_type: "business")
  end

  def create
    @user = User.new(business_user_params)
    @user.account_type = "business"
    @user.role = "customer"

    if @user.save
      sign_in(@user)

      redirect_to root_path,
                  notice: "Votre compte professionnel a été créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def business_user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :password,
      :password_confirmation,
      :company_name,
      :siret
    )
  end
end
