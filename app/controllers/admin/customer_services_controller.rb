class Admin::CustomerServicesController < Admin::BaseController
  before_action :set_customer
  before_action :set_business
  before_action :set_service, only: %i[edit update destroy]

  def new
    @service = @business.services.new(
      status: "active",
      minutes_duration: 30
    )
  end

  def create
    @service = @business.services.new(service_params)

    if @service.save
      redirect_to admin_customer_path(
                    @customer,
                    tab: "services"
                  ),
                  notice: "Service was added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service.update(service_params)
      redirect_to admin_customer_path(
                    @customer,
                    tab: "services"
                  ),
                  notice: "Service was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy!

    redirect_to admin_customer_path(
                  @customer,
                  tab: "services"
                ),
                notice: "Service was removed successfully.",
                status: :see_other
  end

  private

  def set_customer
    @customer = User
                  .where(role: :business)
                  .find(params[:customer_id])
  end

  def set_business
    @business = @customer.business

    return if @business.present?

    redirect_to admin_customer_path(@customer),
                alert: "This customer does not have a business profile."
  end

  def set_service
    @service = @business.services.find(params[:id])
  end

  def service_params
    params.require(:service).permit(
      :name,
      :description,
      :price,
      :minutes_duration,
      :status,
      :deposit_enabled,
      :deposit,
      :icon
    )
  end
end