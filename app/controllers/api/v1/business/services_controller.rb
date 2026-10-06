module Api
  module V1
    module Business
      class ServicesController < ApplicationController
        skip_before_action :verify_authenticity_token

        # ============================================
        # GET SERVICES
        # ============================================

        def get_services
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          services = business.services
                             .includes(
                               :service_category,
                               :service_times,
                               business_agents: :user
                             )
                             .order(created_at: :desc)

          render json: {
            services: services.map do |service|
              serialize_service(service)
            end
          }, status: :ok
        end


        # ============================================
        # GET SERVICE
        # ============================================

        def get_service
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          service = business.services.find_by(
            id: params[:service_id]
          )

          unless service
            return render json: {
              error: "Service not found"
            }, status: :not_found
          end

          render json: {
            service: serialize_service(service)
          }, status: :ok
        end


        # ============================================
        # CREATE SERVICE
        # ============================================

        def create_service
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          service = business.services.new(
            service_params(business)
          )

          # If custom service times are disabled,
          # remove any submitted times.
          if service_times_enabled?(business) &&
             !custom_service_times?

            service.service_times.clear
          end

          if service.save
            render json: {
              message: "Service created successfully",
              service: serialize_service(service)
            }, status: :created
          else
            render json: {
              errors: service.errors.full_messages
            }, status: :unprocessable_entity
          end
        end


        # ============================================
        # UPDATE SERVICE
        # ============================================

        def update_service
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          service = business.services.find_by(
            id: params[:service_id]
          )

          unless service
            return render json: {
              error: "Service not found"
            }, status: :not_found
          end

          service.assign_attributes(
            service_params(business)
          )

          # Remove service times when the user switches
          # custom service times off.
          if service_times_enabled?(business) &&
             !custom_service_times?

            service.service_times.destroy_all
          end

          if service.save
            render json: {
              message: "Service updated successfully",
              service: serialize_service(service.reload)
            }, status: :ok
          else
            render json: {
              errors: service.errors.full_messages
            }, status: :unprocessable_entity
          end
        end


        # ============================================
        # REMOVE SERVICE IMAGE
        # ============================================

        def remove_image
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          service = business.services.find_by(
            id: params[:service_id]
          )

          unless service
            return render json: {
              error: "Service not found"
            }, status: :not_found
          end

          unless business.feature_enabled?(:service_images)
            return render json: {
              error: "Service images are not available on your plan"
            }, status: :forbidden
          end

          service.image.purge if service.image.attached?

          render json: {
            message: "Service image removed successfully",
            service: serialize_service(service.reload)
          }, status: :ok
        end


        # ============================================
        # FORM OPTIONS
        # Categories, agents and feature availability
        # ============================================

        def options
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          agents = business.business_agents
                           .where(status: "active")
                           .includes(:user)

          render json: {
            features: {
              service_images:
                business.feature_enabled?(:service_images),

              service_categories:
                business.feature_enabled?(:service_categories),

              service_times:
                business.feature_enabled?(:service_times),

              stripe_ready:
                business.stripe_ready?
            },

            categories: business.service_categories.map do |category|
              {
                id: category.id,
                name: category.name
              }
            end,

            agents: agents.map do |agent|
              {
                id: agent.id,
                user_id: agent.user_id,
                name: agent.user.full_name,
                email: agent.user.email
              }
            end,

            statuses: ::Service::STATUSES,

            icons: ::Service::ICONS.map do |name, label|
              {
                name: name,
                label: label
              }
            end
          }, status: :ok
        end


        def delete_service
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          service = business.services.find_by(
            id: params[:service_id]
          )

          unless service
            return render json: {
              error: "Service not found"
            }, status: :not_found
          end

          service.destroy!

          render json: {
            message: "Service deleted successfully"
          }, status: :ok
        end


        private


        # ============================================
        # SERVICE PARAMS
        # ============================================

        def service_params(business)
          permitted = params.permit(
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

          # Images require the service_images feature.
          unless business.feature_enabled?(:service_images)
            permitted.delete(:image)
          end

          # Categories require the service_categories feature.
          unless business.feature_enabled?(:service_categories)
            permitted.delete(:service_category_id)
          end

          # Custom times require the service_times feature.
          unless business.feature_enabled?(:service_times)
            permitted.delete(:custom_service_times)
            permitted.delete(:service_times_attributes)
          end

          permitted
        end


        # ============================================
        # SERIALIZER
        # ============================================

        def serialize_service(service)
          {
            id: service.id,
            business_id: service.business_id,

            name: service.name,
            description: service.description,

            price: service.price,
            minutes_duration: service.minutes_duration,

            status: service.status,

            deposit_enabled: service.deposit_enabled,
            deposit: service.deposit,

            icon: service.icon,

            created_at: service.created_at,
            updated_at: service.updated_at,

            # ----------------------------------------
            # IMAGE
            # ----------------------------------------

            image: service.image.attached? ? {
              url: url_for(service.image),
              filename: service.image.filename.to_s,
              content_type: service.image.content_type
            } : nil,

            # ----------------------------------------
            # CATEGORY
            # ----------------------------------------

            service_category_id: service.service_category_id,

            category: service.service_category ? {
              id: service.service_category.id,
              name: service.service_category.name
            } : nil,

            # ----------------------------------------
            # CUSTOM TIMES
            # ----------------------------------------

            custom_service_times: service.service_times.any?,

            service_times: service.service_times.map do |service_time|
              {
                id: service_time.id,

                start_time:
                  service_time.start_time&.strftime("%H:%M"),

                end_time:
                  service_time.end_time&.strftime("%H:%M")
              }
            end,

            # ----------------------------------------
            # AGENTS
            # ----------------------------------------

            business_agent_ids:
              service.business_agents.pluck(:id),

            agents: service.business_agents.map do |agent|
              {
                id: agent.id,
                user_id: agent.user_id,
                name: agent.user.full_name,
                email: agent.user.email
              }
            end
          }
        end


        # ============================================
        # HELPERS
        # ============================================

        def service_times_enabled?(business)
          business.feature_enabled?(:service_times)
        end


        def custom_service_times?
          ActiveModel::Type::Boolean.new.cast(
            params[:custom_service_times]
          )
        end


        def authenticate_api_key!
          provided_api_key =
            request.headers["X-API-Key"]

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
              error: "Invalid or missing API key"
            }, status: :unauthorized
          end
        end
      end
    end
  end
end