
module Api
  module V1
    module Agent
      class ServicesController < Api::V1::BaseController

        before_action :authenticate_api_key!
        before_action :authenticate_agent!
        before_action :set_business
        before_action :set_service, only: [:show]

        # ================================================
        # GET /api/v1/agent/:id/services
        # ================================================

        def index
          services_scope = @business.services

          statistics = {
            total_services: services_scope.count,
            active_services: services_scope.active.count,
            inactive_services: services_scope.inactive.count,
            average_price: (
              services_scope.active.average(:price) || 0
            ).to_f.round(2)
          }

          services = services_scope
                       .includes(:service_category, image_attachment: :blob)
                       .order(:name)

          if params[:q].present?
            search = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

            services = services.where(
              "services.name ILIKE :search OR services.description ILIKE :search",
              search: search
            )
          end

          render json: {
            success: true,
            message: "Services loaded successfully.",
            business: {
              id: @business.id,
              business_name: @business.business_name
            },
            statistics: statistics,
            search: params[:q].to_s,
            services: services.map { |service| service_json(service) }
          }, status: :ok
        end

        # ================================================
        # GET /api/v1/agent/:id/service/:service_id
        # ================================================

        def show
          render json: {
            success: true,
            message: "Service loaded successfully.",
            service: service_json(@service)
          }, status: :ok
        end

        private

        # ================================================
        # API KEY AUTHENTICATION
        # ================================================

        def authenticate_api_key!
          provided_api_key = request.headers["X-API-Key"]

          expected_api_key =
            ENV["SECURE_MY_SLOT_API_KEY"].presence ||
            Rails.application.credentials.secure_my_slot_api_key

          unless provided_api_key.present? &&
                 expected_api_key.present? &&
                 ActiveSupport::SecurityUtils.secure_compare(
                   provided_api_key,
                   expected_api_key
                 )

            render json: {
              success: false,
              error: "Invalid or missing API key"
            }, status: :unauthorized
          end
        end

        # ================================================
        # AGENT AUTHENTICATION
        # ================================================

        def authenticate_agent!
          unless current_user && current_user.role.to_s == "agent"
            return render json: {
              success: false,
              error: "Agent authentication required"
            }, status: :unauthorized
          end

          unless params[:id].to_s == current_user.id.to_s
            return render json: {
              success: false,
              error: "You cannot access another agent's services"
            }, status: :forbidden
          end
        end

        # ================================================
        # FIND AGENT BUSINESS
        # ================================================

        def set_business
          assignment = BusinessAgent
                         .includes(:business)
                         .find_by(
                           agent_id: current_user.id,
                           status: "active"
                         )

          unless assignment
            return render json: {
              success: false,
              error: "No active business assignment found"
            }, status: :forbidden
          end

          @business = assignment.business

          unless @business
            render json: {
              success: false,
              error: "Business not found"
            }, status: :not_found
          end
        end

        # ================================================
        # FIND SERVICE
        # ================================================

        def set_service
          @service = @business.services
                              .includes(:service_category, image_attachment: :blob)
                              .find_by(id: params[:service_id])

          unless @service
            render json: {
              success: false,
              error: "Service not found"
            }, status: :not_found
          end
        end

        # ================================================
        # SERVICE JSON
        # ================================================

        def service_json(service)
          {
            id: service.id,
            name: service.name,
            description: service.description,
            status: service.status,
            active: service.status == "active",

            icon: service.icon.presence || "calendar-check",

            image_url: (
              if service.image.attached?
                rails_blob_url(
                  service.image,
                  host: request.base_url
                )
              end
            ),

            service_category: (
              if service.service_category.present?
                {
                  id: service.service_category.id,
                  name: service.service_category.name
                }
              end
            ),

            minutes_duration: service.minutes_duration,

            price: (service.price || 0).to_f.round(2),

            deposit_enabled: service.deposit_enabled?,
            deposit: (
              service.deposit_enabled? && service.deposit.present? ?
                service.deposit.to_f.round(2) :
                nil
            ),

            deposit_required: (
              service.deposit_enabled? &&
                service.deposit.present?
            )
          }
        end

      end
    end
  end
end
