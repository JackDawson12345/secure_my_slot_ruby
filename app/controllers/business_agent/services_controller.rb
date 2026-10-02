# app/controllers/business_agent/services_controller.rb

class BusinessAgent::ServicesController < BusinessAgent::BaseController
  before_action :set_service, only: :show

  def index
    services_scope = @business.services

    @total_services = services_scope.count
    @active_services_count = services_scope.active.count
    @inactive_services_count = services_scope.inactive.count
    @average_price = services_scope.active.average(:price) || 0

    @services = services_scope
                  .includes(:service_category)
                  .order(:name)

    if params[:q].present?
      search = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

      @services = @services.where(
        "services.name ILIKE :search OR services.description ILIKE :search",
        search: search
      )
    end
  end

  def show
  end


  def set_service
    @service = @business.services
                        .includes(:service_category)
                        .find(params[:id])
  end
end