
class Admin::CustomerServicesController < Admin::BaseController
  before_action :set_customer
  before_action :set_business
  before_action :set_service, only: %i[edit update destroy remove_image]
  before_action :set_agents, only: %i[new create edit update]

  def new
    @service = @business.services.new(
      status: "active",
      minutes_duration: 30
    )

    @service.service_times.build
  end

  def create
    @service = @business.services.new(service_params)

    clear_custom_times_if_disabled

    if @service.save
      redirect_to services_path,
                  notice: "Service was added successfully."
    else
      prepare_service_times
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_service_times
  end

  def update
    @service.assign_attributes(service_params)

    clear_custom_times_if_disabled

    if @service.save
      redirect_to services_path,
                  notice: "Service was updated successfully."
    else
      prepare_service_times
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy!

    redirect_to services_path,
                notice: "Service was removed successfully.",
                status: :see_other
  end

  def remove_image
    @service.image.purge if @service.image.attached?

    redirect_to edit_admin_customer_service_path(@customer, @service),
                notice: "Service image removed successfully.",
                status: :see_other
  end

  private

  def services_path
    admin_customer_path(@customer, tab: "services")
  end

  def set_customer
    @customer = User.where(role: :business).find(params[:customer_id])
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

  def set_agents
    @agents = @business.business_agents
                       .where(status: "active")
                       .includes(:user)
  end

  def prepare_service_times
    @service.service_times.build if @service.service_times.empty?
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
      business_agent_ids: [],
      service_times_attributes: [
        :id,
        :start_time,
        :end_time,
        :_destroy
      ]
    )

    if permitted[:service_category_id].present?
      @business.service_categories.find(
        permitted[:service_category_id]
      )
    end

    unless @business.feature_enabled?(:service_images)
      permitted.delete(:image)
    end

    unless @business.feature_enabled?(:service_categories)
      permitted.delete(:service_category_id)
    end

    unless @business.feature_enabled?(:service_times)
      permitted.delete(:custom_service_times)
      permitted.delete(:service_times_attributes)
    end

    permitted
  end

  def clear_custom_times_if_disabled
    return unless @business.feature_enabled?(:service_times)
    return if custom_service_times?

    @service.service_times.clear
  end

  def custom_service_times?
    ActiveModel::Type::Boolean.new.cast(
      params.dig(:service, :custom_service_times)
    )
  end
end
