module Api
  module V1
    module Customer
      class GetInfoController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authenticate_api_key!

        def get_dashboard_details

          customer = ::User.find(params[:id])
          bookings = ::Booking.where(user_id: customer.id)
          upcoming_bookings = bookings
                                  .where.not(status: "cancelled")
                                .where("date >= ?", Date.today)
                                .order(date: :asc, time: :asc)
                                .limit(3)
          upcoming_bookings_count = bookings
                                      .where.not(status: "cancelled")
                                      .where("date >= ?", Date.today)
                                      .count
          completed_bookings_count = bookings
                                       .where(status: "completed")
                                       .count
          total_bookings_count = bookings.count
          todays_bookings_count = bookings
                                    .where(date: Date.today)
                                    .where.not(status: "cancelled")
                                    .count
          businesses_booked_with_count = bookings
                                           .distinct
                                           .count(:business_id)
          next_booking = bookings
                           .where.not(status: "cancelled")
                           .where("date >= ?", Date.today)
                           .order(date: :asc, time: :asc)
                           .first

          render json: {
            dashboard_figures: {
              total_appointments: total_bookings_count,
              todays_appointments: todays_bookings_count,
              upcoming_appointments: upcoming_bookings_count,
              completed_appointments: completed_bookings_count,
              businesses: businesses_booked_with_count,
              next_appointment: {
                date: next_booking&.date,
                time: next_booking&.time
              }
            },
            customer: {
              id: customer.id,
              email: customer.email,
              role: customer.role,
              first_name: customer.first_name,
              last_name: customer.last_name,
              phone_number: customer.phone_number,
              terms_accepted: customer.terms_accepted,
              terms_accepted_at: customer.terms_accepted_at,
              marketing_consent: customer.marketing_consent,
            },
            upcoming_appointments: upcoming_bookings.map do |booking|
              service = ::Service.find(booking.service_id)
              business = ::Business.find(service.business_id)
              {
                id: booking.id,
                business: {
                  id: business.id,
                  name: business.business_name,
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
