module Api
  module V1
    module Business
      class ServicesController < ApplicationController

        skip_before_action :verify_authenticity_token

        def get_services
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          services = ::Service.where(business_id: business.id)

          render json: {
            services: services.map do |service|
              {
                id: service.id,
                business_id: service.business_id,
                name: service.name,
                description: service.description,
                price: service.price,
                minutes_duration: service.minutes_duration,
                status: service.status,
                created_at: service.created_at,
                updated_at: service.updated_at,
                deposit_enabled: service.deposit_enabled,
                deposit: service.deposit,
                icon: service.icon
              }
            end
          }, status: :ok
        end


        def get_service
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          service = business.services.find_by(id: params[:service_id])

          unless service
            return render json: {
              error: "Service not found"
            }, status: :not_found
          end

          render json: {
            service: {
              id: service.id,
              business_id: service.business_id,
              name: service.name,
              description: service.description,
              price: service.price,
              minutes_duration: service.minutes_duration,
              status: service.status,
              created_at: service.created_at,
              updated_at: service.updated_at,
              deposit_enabled: service.deposit_enabled,
              deposit: service.deposit,
              icon: service.icon
            }
          }, status: :ok
        end


        def update_service

          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          service = business.services.find_by(id: params[:service_id])

          unless service
            return render json: {
              error: "Service not found"
            }, status: :not_found
          end

          if service.update(service_params)
            render json: {
              message: "Service updated successfully",
              service: {
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
                updated_at: service.updated_at
              }
            }, status: :ok
          else
            render json: {
              errors: service.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def create_service

          business = ::Business.find_by(id: params[:id])


          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end


          service = business.services.new(service_params)


          if service.save

            render json: {
              message: "Service created successfully",
              service: service
            }, status: :created


          else

            render json: {
              errors: service.errors.full_messages
            }, status: :unprocessable_entity

          end

        end


        private

        def service_params
          params.permit(
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
    end
  end
end