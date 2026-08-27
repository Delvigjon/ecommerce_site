class Backoffice::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  layout "backoffice"

  private

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: "Accès non autorisé."
  end
end
