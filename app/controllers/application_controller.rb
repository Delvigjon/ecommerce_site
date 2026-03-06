class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    added = [
      :account_type,
      :first_name, :last_name, :phone,
      :company_name, :siret
    ]

    devise_parameter_sanitizer.permit(:sign_up, keys: added)
    devise_parameter_sanitizer.permit(:account_update, keys: added)
  end
end
