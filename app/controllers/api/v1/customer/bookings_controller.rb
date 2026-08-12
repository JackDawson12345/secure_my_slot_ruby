module Api
  module V1
    module Customer
      class BookingsController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authenticate_api_key!

        def get_booking

          customer = ::User.find(params[:id])
          booking = ::Booking.find(params[:booking_id])

          unless booking.user_id == customer.id
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          service = ::Service.find(booking.service_id)
          business = ::Business.find(booking.business_id)
          businessSettings = ::BusinessSetting.find_by(business_id: business.id)

          render json: {
            booking: {
              id: booking.id,
              business: {
                id: business.id,
                name: business.business_name,
                category: businessSettings.business_category,
                address: {
                  address_line_1: businessSettings.address_line_1,
                  address_line_2: businessSettings.address_line_2,
                  town_or_city: businessSettings.town_or_city,
                  postcode: businessSettings.postcode,
                  country: businessSettings.country,
                },
                phone_number: businessSettings.phone_number
              },
              user_id: booking.user_id,
              user_name: booking.user.first_name + ' ' + booking.user.last_name,
              service: {
                id: service.id,
                name: service.name,
                description: service.description,
                price: service.price,
                minutes_duration: service.minutes_duration
              },
              date: booking.date,
              time: booking.time,
              status: booking.status,
              created_at: booking.created_at,
              updated_at: booking.updated_at,
              payment_status: booking.payment_status,
              stripe_checkout_session_id: booking.stripe_checkout_session_id,
              stripe_payment_intent_id: booking.stripe_payment_intent_id,
              notes: booking.notes,
              reminder_email_sent_at: booking.reminder_email_sent_at,
              reminder_sms_sent_at: booking.reminder_sms_sent_at,
              amount_paid: booking.amount_paid
            }
          }, status: :ok
        end

        def get_bookings
          customer = ::User.find(params[:id])

          unless customer
            return render json: {
              error: "Customer not found."
            }, status: :not_found
          end

          bookings = ::Booking.where(user_id: customer.id)

          if params[:status].present?
            bookings = bookings.where(status: params[:status])
          end

          bookings_per_page = params[:bookings_per_page].to_i
          page = params[:page].to_i

          bookings_per_page = 10 if bookings_per_page.zero?
          page = 1 if page.zero?

          total_bookings = bookings.count
          total_pages = (total_bookings.to_f / bookings_per_page).ceil

          paginated_bookings = bookings
                                 .order(date: :asc, time: :asc)
                                 .limit(bookings_per_page)
                                 .offset((page - 1) * bookings_per_page)

          render json: {
            total_bookings: total_bookings,
            bookings_per_page: bookings_per_page,
            current_page: page,
            total_pages: total_pages,
            status_filter: params[:status],
            bookings: paginated_bookings.map do |booking|
              business = ::Business.find(booking.business_id)
              businessSettings = ::BusinessSetting.find_by(business_id: business.id)
              service = ::Service.find(booking.service_id)
              {
                id: booking.id,
                business: {
                  id: business.id,
                  name: business.business_name,
                  category: businessSettings.business_category,
                  address: {
                    address_line_1: businessSettings.address_line_1,
                    address_line_2: businessSettings.address_line_2,
                    town_or_city: businessSettings.town_or_city,
                    postcode: businessSettings.postcode,
                    country: businessSettings.country,
                  },
                  phone_number: businessSettings.phone_number
                },
                user_id: booking.user_id,
                user_name: booking.user.first_name + ' ' + booking.user.last_name,
                service: {
                  id: service.id,
                  name: service.name,
                  description: service.description,
                  price: service.price,
                  minutes_duration: service.minutes_duration
                },
                date: booking.date,
                time: booking.time,
                status: booking.status,
                created_at: booking.created_at,
                updated_at: booking.updated_at,
                payment_status: booking.payment_status,
                stripe_checkout_session_id: booking.stripe_checkout_session_id,
                stripe_payment_intent_id: booking.stripe_payment_intent_id,
                notes: booking.notes,
                reminder_email_sent_at: booking.reminder_email_sent_at,
                reminder_sms_sent_at: booking.reminder_sms_sent_at,
                amount_paid: booking.amount_paid
              }
            end
          }, status: :ok
        end


        private

        def authenticate_api_key!
          provided_api_key = request.headers["X-API-Key"]
          expected_api_key = Rails.application.credentials.secure_my_slot_api_key

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

