module Api
  module V1
    module Business
      class SettingsController < ApplicationController
        skip_before_action :verify_authenticity_token

        # =========================================================
        # GET /api/v1/business/:id/settings
        # =========================================================
        def show
          business = ::Business.find_by(id: params[:id])

          unless business
            render json: {
              error: "Business not found"
            }, status: :not_found

            return
          end

          settings = business.business_setting || business.create_business_setting
          user = business.user

          unless user
            render json: {
              error: "User not found"
            }, status: :not_found

            return
          end

          render json: {
            settings: settings_json(
              business,
              settings
            ),

            user: user_json(user),

            features: {
              automated_reminders:
                business.feature_enabled?(:automated_reminders),

              client_birthday_reminders:
                business.feature_enabled?(:client_birthday_reminders)
            }
          }, status: :ok
        end

        # =========================================================
        # PATCH /api/v1/business/:id/settings
        # =========================================================
        def update
          business = ::Business.find_by(id: params[:id])

          unless business
            render json: {
              error: "Business not found"
            }, status: :not_found

            return
          end

          settings =
            business.business_setting ||
            business.create_business_setting

          user = business.user

          unless user
            render json: {
              error: "User not found"
            }, status: :not_found

            return
          end

          ActiveRecord::Base.transaction do
            permitted_settings =
              filtered_settings_params(
                business
              )

            settings.update!(
              permitted_settings
            )

            user.update!(
              user_params
            ) if user_params.present?

            # Keep the Business model in sync with the settings
            business_updates = {}

            if permitted_settings.key?(:business_category)
              business_updates[:category] =
                permitted_settings[:business_category]
            end

            if permitted_settings.key?(:phone_number)
              business_updates[:phone_number] =
                permitted_settings[:phone_number]
            end

            business.update!(
              business_updates
            ) if business_updates.present?

            # Keep the user's phone number in sync
            if permitted_settings.key?(:phone_number)
              user.update!(
                phone_number:
                  permitted_settings[:phone_number]
              )
            end
          end

          render json: {
            message: "Settings updated successfully",

            settings: settings_json(
              business,
              settings
            ),

            user: user_json(user),

            features: {
              automated_reminders:
                business.feature_enabled?(:automated_reminders),

              client_birthday_reminders:
                business.feature_enabled?(:client_birthday_reminders)
            }
          }, status: :ok

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        # =========================================================
        # PATCH /api/v1/business/:id/settings/password
        # =========================================================
        def update_password
          business = ::Business.find_by(id: params[:id])

          unless business
            render json: {
              error: "Business not found"
            }, status: :not_found

            return
          end

          user = business.user

          unless user
            render json: {
              error: "User not found"
            }, status: :not_found

            return
          end

          unless user.valid_password?(
            password_params[:current_password]
          )
            render json: {
              error: "Current password is incorrect"
            }, status: :unprocessable_entity

            return
          end

          if password_params[:new_password] !=
             password_params[:new_password_confirmation]

            render json: {
              error: "New passwords do not match"
            }, status: :unprocessable_entity

            return
          end

          if user.update(
            password: password_params[:new_password],
            password_confirmation:
              password_params[:new_password_confirmation]
          )

            render json: {
              message: "Password updated successfully"
            }, status: :ok

          else
            render json: {
              errors: user.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        # =========================================================
        # SETTINGS JSON
        # =========================================================
        def settings_json(business, settings)
          {
            id: settings.id,

            # Business details
            business_name:
              settings.business_name,

            business_category:
              settings.business_category,

            phone_number:
              settings.phone_number,

            business_email:
              settings.business_email,

            business_description:
              settings.business_description,

            check_verify_link:
              settings.check_verify_link,

            # Logo
            logo_url:
              attachment_url(settings.logo),

            logo_attached:
              settings.logo.attached?,

            # Favicon
            favicon_url:
              attachment_url(settings.favicon),

            favicon_attached:
              settings.favicon.attached?,

            # Address
            address_line_1:
              settings.address_line_1,

            address_line_2:
              settings.address_line_2,

            town_or_city:
              settings.town_or_city,

            postcode:
              settings.postcode,

            country:
              settings.country,

            # Booking page
            booking_page_address:
              business.page_address,

            booking_page_url:
              booking_page_url(business),

            booking_page_live:
              settings.booking_page_live,

            # Booking preferences
            automatically_confirm_bookings:
              settings.automatically_confirm_bookings,

            allow_customer_cancellations:
              settings.allow_customer_cancellations,

            require_customer_phone_number:
              settings.require_customer_phone_number,

            cancellation_notice_hours:
              settings.cancellation_notice_hours,

            # Notifications
            new_booking_notifications:
              settings.new_booking_notifications,

            cancellation_notifications:
              settings.cancellation_notifications,

            daily_appointment_summary:
              settings.daily_appointment_summary,

            birthday_reminder:
              settings.birthday_reminder,

            # Timestamps
            created_at:
              settings.created_at,

            updated_at:
              settings.updated_at
          }
        end

        # =========================================================
        # USER JSON
        # =========================================================
        def user_json(user)
          {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            phone_number: user.phone_number
          }
        end

        # =========================================================
        # ATTACHMENT URL
        # =========================================================
        def attachment_url(attachment)
          return nil unless attachment.attached?

          rails_blob_url(
            attachment,
            host: request.base_url
          )
        end

        # =========================================================
        # BOOKING PAGE URL
        # =========================================================
        def booking_page_url(business)
          return nil if business.page_address.blank?

          "https://#{business.page_address}.book-pilot.co.uk"
        end

        # =========================================================
        # SETTINGS PARAMS
        # =========================================================
        def settings_params
          params.require(:settings).permit(
            :business_name,
            :business_category,
            :phone_number,
            :business_email,
            :business_description,

            :logo,
            :favicon,
            :check_verify_link,

            :address_line_1,
            :address_line_2,
            :town_or_city,
            :postcode,
            :country,

            :booking_page_live,

            :automatically_confirm_bookings,
            :allow_customer_cancellations,
            :require_customer_phone_number,

            :cancellation_notice_hours,

            :new_booking_notifications,
            :cancellation_notifications,
            :daily_appointment_summary,
            :birthday_reminder
          )
        end

        # =========================================================
        # FEATURE RESTRICTED SETTINGS
        # =========================================================
        def filtered_settings_params(business)
          permitted =
            settings_params.to_h.symbolize_keys

          unless business.feature_enabled?(
            :automated_reminders
          )
            permitted.delete(
              :daily_appointment_summary
            )
          end

          unless business.feature_enabled?(
            :client_birthday_reminders
          )
            permitted.delete(
              :birthday_reminder
            )
          end

          permitted
        end

        # =========================================================
        # USER PARAMS
        # =========================================================
        def user_params
          params.fetch(
            :user,
            {}
          ).permit(
            :first_name,
            :last_name,
            :email
          )
        end

        # =========================================================
        # PASSWORD PARAMS
        # =========================================================
        def password_params
          params.require(:password).permit(
            :current_password,
            :new_password,
            :new_password_confirmation
          )
        end
      end
    end
  end
end