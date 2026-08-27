# app/controllers/backoffice/dashboard_controller.rb

module Backoffice
  class DashboardController < BaseController

    def index
      @products_count = Product.count
      @orders_count   = Order.count
      @users_count    = User.where(role: "customer").count
      @offers_count   = Offer.count

      @recent_orders = Order
        .includes(:user)
        .order(created_at: :desc)
        .limit(5)
    end

  end
end
