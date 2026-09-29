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

    @service.service_times.build
  end

  def create
    @service = @business.services.new(service_params)

    if service_times_enabled? && !custom_service_times?
      @service.service_times.clear
    end

    if @service.save
      redirect_to business_services_path,
                  notice: "Service was created successfully."
    else
      @service.service_times.build if @service.service_times.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @service.service_times.build if @service.service_times.empty?
  end

  def update
    @service.assign_attributes(service_params)

    if service_times_enabled? && !custom_service_times?
      @service.service_times.destroy_all
    end

    if @service.save
      redirect_to business_service_path(@service),
                  notice: "Service was updated successfully."
    else
      @service.service_times.build if @service.service_times.empty?
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
    permitted = params.require(:service).permit(
      :name,
      :description,
      :price,
      :minutes_duration,
      :status,
      :deposit_enabled,
      :deposit,
      :icon,
      :image,
      :service_category_id,
      :custom_service_times,
      service_times_attributes: [
        :id,
        :start_time,
        :end_time,
        :_destroy
      ]
    )

    permitted.delete(:image) unless @business.feature_enabled?(:service_images)

    permitted.delete(:service_category_id) unless @business.feature_enabled?(:service_categories)

    unless @business.feature_enabled?(:service_times)
      permitted.delete(:custom_service_times)
      permitted.delete(:service_times_attributes)
    end

    permitted
  end

  def service_times_enabled?
    @business.feature_enabled?(:service_times)
  end

  def custom_service_times?
    ActiveModel::Type::Boolean.new.cast(
      params.dig(:service, :custom_service_times)
    )
  end
end