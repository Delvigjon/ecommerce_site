class Backoffice::ProductsController < Backoffice::BaseController
  before_action :set_product, only: %i[show edit update destroy]

  def index
    @products = Product.order(created_at: :desc)
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to backoffice_product_path(@product),
                  notice: "Le produit a été créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to backoffice_product_path(@product),
                  notice: "Le produit a été mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy!

    redirect_to backoffice_products_path,
                notice: "Le produit a été supprimé."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :price,
      :stock,
      :image_url
    )
  end
end
