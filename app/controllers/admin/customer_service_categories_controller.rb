
class Admin::CustomerServiceCategoriesController < Admin::BaseController
  before_action :set_customer
  before_action :set_business
  before_action :set_category, only: %i[edit update destroy]

  def new
    @category = @business.service_categories.new
  end

  def create
    @category = @business.service_categories.new(category_params)

    if @category.save
      redirect_to admin_customer_path(
                    @customer,
                    tab: "service_categories"
                  ),
                  notice: "Service category created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to admin_customer_path(
                    @customer,
                    tab: "service_categories"
                  ),
                  notice: "Service category updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy!

    redirect_to admin_customer_path(
                  @customer,
                  tab: "service_categories"
                ),
                notice: "Service category removed successfully."
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to admin_customer_path(
                  @customer,
                  tab: "service_categories"
                ),
                alert: "This service category could not be removed."
  end

  private

  def set_customer
    @customer = User.where(role: 1).find(params[:customer_id])
  end

  def set_business
    @business = @customer.business

    return if @business.present?

    redirect_to admin_customer_path(@customer),
                alert: "This customer does not have a business profile."
  end

  def set_category
    @category = @business.service_categories.find(params[:id])
  end

  def category_params
    params.require(:service_category).permit(:name)
  end
end
