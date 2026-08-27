class OrdersController < ApplicationController
  before_action :authenticate_user!

  before_action :set_order,
                only: %i[
                  show
                  invoice
                ]

  # =========================================================
  # INDEX
  # =========================================================

  def index
    @orders =
      current_user
        .orders
        .includes(order_items: :product)
        .order(created_at: :desc)
  end


  # =========================================================
  # NEW
  # =========================================================

  def new
    @cart =
      current_user.cart

    if @cart.blank? || @cart.cart_items.empty?
      redirect_to products_path,
                  alert: "Votre panier est vide."
      return
    end

    @order =
      Order.new
  end


  # =========================================================
  # SHOW
  # =========================================================

  def show
  end


  # =========================================================
  # INVOICE
  # =========================================================

  def invoice
    unless @order.status.in?(
      %w[
        paid
        processing
        shipped
        delivered
        completed
      ]
    )
      redirect_to order_path(@order),
                  alert: "La facture n'est pas encore disponible."
      return
    end

    @order.ensure_invoice!

    pdf =
      Invoices::PdfGenerator
        .new(@order)
        .call

    send_data(
      pdf,
      filename: "#{@order.invoice_number}.pdf",
      type: "application/pdf",
      disposition: "attachment"
    )
  end


  private


  # =========================================================
  # ORDER
  # =========================================================

  def set_order
    @order =
      current_user
        .orders
        .includes(order_items: :product)
        .find(params[:id])
  end
end
