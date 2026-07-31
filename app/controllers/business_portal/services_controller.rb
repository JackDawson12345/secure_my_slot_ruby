class BusinessPortal::ServicesController < BusinessPortal::BaseController
  before_action :set_business
  before_action :set_service, only: %i[show edit update destroy]

  def index
    @services = @business.services.order(created_at: :desc)

    @total_services = @services.count
    @active_services_count = @services.active.count
    @inactive_services_count = @services.inactive.count
    @average_price = @services.active.average(:price) || 0
  end

  def show
  end

  def new
    @service = @business.services.new(
      status: "active",
      minutes_duration: 30
    )
  end

  def create
    @service = @business.services.new(service_params)

    if @service.save
      redirect_to business_service_path(@service),
                  notice: "Service was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service.update(service_params)
      redirect_to business_service_path(@service),
                  notice: "Service was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy

    redirect_to business_services_path,
                notice: "Service was deleted successfully.",
                status: :see_other
  end

  private

  def set_business
    @business = current_user.business

    redirect_to root_path, alert: "Business not found." unless @business
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
      :status
    )
  end
end