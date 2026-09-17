class BusinessPortal::ServicesController < BusinessPortal::BaseController
  before_action :set_business
  before_action :set_service, only: %i[show edit update destroy remove_image]

  def index
    services_scope = @business.services

    # ----------------------------------------
    # Statistics
    # Always based on all services
    # ----------------------------------------

    @total_services = services_scope.count
    @active_services_count = services_scope.active.count
    @inactive_services_count = services_scope.inactive.count
    @average_price = services_scope.active.average(:price) || 0

    # ----------------------------------------
    # Search
    # Searches name and description
    # ----------------------------------------

    if params[:q].present?
      search = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

      services_scope = services_scope.where(
        "name ILIKE :search OR description ILIKE :search",
        search: search
      )
    end

    @services = services_scope.order(created_at: :desc)
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
      redirect_to business_services_path,
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

  def remove_image
    @service.image.purge if @service.image.attached?

    redirect_to edit_business_service_path(@service),
                notice: "Service image removed successfully."
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
      :status,
      :deposit_enabled,
      :deposit,
      :icon,
      :image
    )
  end
end