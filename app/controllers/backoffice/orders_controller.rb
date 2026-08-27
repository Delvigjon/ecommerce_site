class Backoffice::OrdersController < Backoffice::BaseController
  before_action :set_order, only: %i[show update]

  def index
    @orders = Order
      .includes(:user)
      .order(created_at: :desc)
  end

  def show
    @order_items = @order.order_items.includes(:product)
  end

  def update
    if @order.update(order_params)
      redirect_to backoffice_order_path(@order),
                  notice: "La commande a été mise à jour."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:status)
  end
end
