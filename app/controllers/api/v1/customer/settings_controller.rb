module Api
  module V1
    module Customer
      class SettingsController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authenticate_api_key!

        def show

          customer = ::User.find_by(id: params[:id])

          unless customer
            render json: {
              error: "Customer not found"
            }, status: :not_found

            return
          end

          settings = customer.customer_setting

          unless settings
            render json: {
              error: "Customer settings not found"
            }, status: :not_found

            return
          end

          render json: {
            settings: settings_json(settings),
            user: user_json(customer)
          }, status: :ok
        end

        def update
          customer = ::User.find_by(id: params[:id])

          unless customer
            render json: {
              error: "Customer not found"
            }, status: :not_found

            return
          end

          settings = customer.customer_setting

          unless settings
            render json: {
              error: "Customer settings not found"
            }, status: :not_found

            return
          end

          ActiveRecord::Base.transaction do
            settings.update!(settings_params)

            if user_params.present?
              customer.update!(user_params)
            end
          end

          render json: {
            message: "Settings updated successfully",
            settings: settings_json(settings.reload),
            user: user_json(customer.reload)
          }, status: :ok

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        def update_password
          customer = ::User.find_by(id: params[:id])

          unless customer
            render json: {
              error: "Customer not found"
            }, status: :not_found

            return
          end

          current_password = password_params[:current_password]
          new_password = password_params[:new_password]
          confirmation = password_params[:new_password_confirmation]

          if current_password.blank?
            render json: {
              error: "Current password is required"
            }, status: :unprocessable_entity

            return
          end

          unless customer.valid_password?(current_password)
            render json: {
              error: "Current password is incorrect"
            }, status: :unprocessable_entity

            return
          end

          if new_password.blank?
            render json: {
              error: "New password cannot be blank"
            }, status: :unprocessable_entity

            return
          end

          if new_password != confirmation
            render json: {
              error: "New passwords do not match"
            }, status: :unprocessable_entity

            return
          end

          if customer.update(
            password: new_password,
            password_confirmation: confirmation
          )
            render json: {
              message: "Password updated successfully"
            }, status: :ok
          else
            render json: {
              errors: customer.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def authenticate_api_key!
          provided_api_key = request.headers["X-API-Key"]
          expected_api_key = Rails.application.credentials.secure_my_slot_api_key

          Rails.logger.info "PROVIDED API KEY PRESENT: #{provided_api_key.present?}"
          Rails.logger.info "EXPECTED API KEY PRESENT: #{expected_api_key.present?}"

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

        def settings_params
          params.require(:settings).permit(
            :date_of_birth,
            :preferred_name,
            :phone_number,
            :preferred_contact_method,

            :address_line_1,
            :address_line_2,
            :town_or_city,
            :postcode,
            :country,

            :booking_confirmations,
            :appointment_reminders,
            :booking_changes,
            :offers_and_service_updates,
            :reminder_timing,
            :reminder_method,

            :latitude,
            :longitude
          )
        end

        def user_params
          params.fetch(:user, {}).permit(
            :first_name,
            :last_name,
            :email
          )
        end

        def password_params
          params.require(:password).permit(
            :current_password,
            :new_password,
            :new_password_confirmation
          )
        end

        def settings_json(settings)
          {
            id: settings.id,

            date_of_birth: settings.date_of_birth,
            preferred_name: settings.preferred_name,
            phone_number: settings.phone_number,
            preferred_contact_method: settings.preferred_contact_method,

            address_line_1: settings.address_line_1,
            address_line_2: settings.address_line_2,
            town_or_city: settings.town_or_city,
            postcode: settings.postcode,
            country: settings.country,

            booking_confirmations: settings.booking_confirmations,
            appointment_reminders: settings.appointment_reminders,
            booking_changes: settings.booking_changes,
            offers_and_service_updates: settings.offers_and_service_updates,
            reminder_timing: settings.reminder_timing,
            reminder_method: settings.reminder_method,

            latitude: settings.latitude,
            longitude: settings.longitude,

            created_at: settings.created_at,
            updated_at: settings.updated_at
          }
        end

        def user_json(user)
          {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            created_at: user.created_at
          }
        end
      end
    end
  end
end