module Api
  module V1
    module Business
      class SettingsController < ApplicationController

        skip_before_action :verify_authenticity_token


        def show

          business = ::Business.find_by(id: params[:id])


          unless business
            render json: {
              error: "Business not found"
            }, status: :not_found

            return
          end



          settings = business.business_setting
          user = ::User.find(business.user_id)

          render json: {

            settings: {

              id: settings.id,

              business_name: settings.business_name,
              business_category: settings.business_category,
              phone_number: settings.phone_number,
              business_email: settings.business_email,
              business_description: settings.business_description,


              address_line_1: settings.address_line_1,
              address_line_2: settings.address_line_2,
              town_or_city: settings.town_or_city,
              postcode: settings.postcode,
              country: settings.country,

              booking_page_address: business.page_address,
              booking_page_live: settings.booking_page_live,


              automatically_confirm_bookings:
                settings.automatically_confirm_bookings,

              allow_customer_cancellations:
                settings.allow_customer_cancellations,

              require_customer_phone_number:
                settings.require_customer_phone_number,


              cancellation_notice_hours:
                settings.cancellation_notice_hours,


              new_booking_notifications:
                settings.new_booking_notifications,

              cancellation_notifications:
                settings.cancellation_notifications,

              daily_appointment_summary:
                settings.daily_appointment_summary,


              created_at: settings.created_at,
              updated_at: settings.updated_at

            },
            user: {
              id: user.id,
              email: user.email,
              first_name: user.first_name,
              last_name: user.last_name,
              phone_number: user.phone_number
            }

          }


        end

        def update

          business = ::Business.find_by(id: params[:id])


          unless business

            render json: {
              error: "Business not found"
            }, status: :not_found

            return

          end


          user = business.user
          settings = business.business_setting


          ActiveRecord::Base.transaction do

            settings.update!(settings_params)

            user.update!(user_params) if user_params.present?

          end


          render json: {

            message: "Settings updated successfully",

            settings: settings,
            user: {
              id: user.id,
              email: user.email,
              first_name: user.first_name,
              last_name: user.last_name,
              phone_number: user.phone_number
            }

          }, status: :ok



        rescue ActiveRecord::RecordInvalid => e

          render json: {
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity

        end

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

          unless user.valid_password?(password_params[:current_password])

            render json: {
              error: "Current password is incorrect"
            }, status: :unprocessable_entity

            return

          end

          if password_params[:new_password] != password_params[:new_password_confirmation]

            render json: {
              error: "New passwords do not match"
            }, status: :unprocessable_entity

            return

          end

          if user.update(
            password: password_params[:new_password],
            password_confirmation: password_params[:new_password_confirmation]
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

        def settings_params

          params.require(:settings).permit(

            :business_name,
            :business_category,
            :phone_number,
            :business_email,
            :business_description,

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
            :daily_appointment_summary

          )

        end

        def user_params

          params.fetch(:user, {}).permit(
            :first_name,
            :last_name,
            :phone_number
          )

        end

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