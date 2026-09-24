class BusinessPortal::ProductsController < BusinessPortal::BaseController

  def index
    @products = current_user.business.products.order(created_at: :desc)

    @total_products = @products.count
    @active_products_count = @products.where(status: "active").count
    @inactive_products_count = @products.where.not(status: "active").count
    @featured_products_count = @products.where(featured: true).count
  end


  def new
    @product = current_user.business.products.new
  end


  def create
    @product = current_user.business.products.new(product_params)

    @product.slug = generate_unique_slug(@product.name)

    if @product.save

      save_product_images

      redirect_to business_products_path,
                  notice: "Product created successfully."
    else
      render :new,
             status: :unprocessable_entity
    end
  end


  def edit
    @product = current_user.business.products.find(params[:id])
  end


  def update
    @product = current_user.business.products.find(params[:id])

    if product_params[:slug].present?
      @product.slug = generate_unique_slug_from_slug(product_params[:slug])
    end

    if @product.update(product_params.merge(slug: @product.slug))

      save_product_images

      redirect_to business_products_path,
                  notice: "Product updated successfully."
    else
      render :edit,
             status: :unprocessable_entity
    end
  end

  def show
    @product = current_user.business.products.find(params[:id])
  end

  def orders
    @orders = current_user.business.orders
  end

  def order
    @order = current_user.business.orders.find(params[:id])
  end

  def update_status
    @order = current_user.business.orders.find(params[:id])
    @order.update(status: params[:status])

    redirect_to order_business_products_path(params[:id]), notice: "Order status updated to" + params[:status]
  end


  private

  def generate_unique_slug(name)
    base_slug = name.parameterize
    slug = base_slug
    counter = 1

    while current_user.business.products.exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    slug
  end

  def generate_unique_slug_from_slug(slug)
    base_slug = slug.parameterize
    new_slug = base_slug
    counter = 1

    while current_user.business.products
                      .where.not(id: @product.id)
                      .exists?(slug: new_slug)

      new_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    new_slug
  end


  def save_product_images
    return unless params[:product][:images].present?

    params[:product][:images].each do |image|

      next unless image.respond_to?(:original_filename)
      next if image.original_filename.blank?

      @product.product_images.create!(
        image: image
      )

    end
  end


  def product_params
    params.require(:product).permit(
      :name,
      :slug,
      :description,
      :short_description,
      :regular_price,
      :sale_price,
      :status,
      :visibility,
      :publish_at,
      :featured_image,
      :tabs,
      :manage_stock,
      :stock_count
    )
  end

end