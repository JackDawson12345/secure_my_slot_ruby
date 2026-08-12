module Api
  module V1
    module Business
      class BookingsController < ApplicationController

        skip_before_action :verify_authenticity_token

        def get_bookings
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          bookings = business.bookings

          # Filter by status if provided
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
              {
                id: booking.id,
                business_id: booking.business_id,
                user_id: booking.user_id,
                user_name: booking.user.first_name + ' ' + booking.user.last_name,
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

        def get_booking
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          booking = business.bookings.find_by(id: params[:booking_id])

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          render json: {
            booking: {
              id: booking.id,
              business_id: booking.business_id,
              user_id: booking.user_id,
              user_name: booking.user.first_name + ' ' + booking.user.last_name,
              date: booking.date,
              time: booking.time,
              status: booking.status,
              payment_status: booking.payment_status,
              stripe_checkout_session_id: booking.stripe_checkout_session_id,
              stripe_payment_intent_id: booking.stripe_payment_intent_id,
              notes: booking.notes,
              reminder_email_sent_at: booking.reminder_email_sent_at,
              reminder_sms_sent_at: booking.reminder_sms_sent_at,
              total_price: booking.service.price,
              amount_paid: booking.amount_paid,
              created_at: booking.created_at,
              updated_at: booking.updated_at,
              users_email: booking.user.email,
              users_phone: booking.user.phone_number
            }
          }, status: :ok
        end

        def update_status
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          booking = business.bookings.find_by(id: params[:booking_id])

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          user = booking.user
          status = params[:status]

          unless %w[confirmed cancelled completed].include?(status)
            return render json: {
              error: "Invalid status. Status must be confirmed, cancelled or completed."
            }, status: :unprocessable_entity
          end

          if booking.update(status: status)
            render json: {
              message: "Booking status updated successfully.",
              booking: {
                id: booking.id,
                business_id: booking.business_id,
                user_id: booking.user_id,
                date: booking.date,
                time: booking.time,
                status: booking.status,
                payment_status: booking.payment_status,
                notes: booking.notes,
                created_at: booking.created_at,
                updated_at: booking.updated_at
              }
            }, status: :ok

            if user.customer_setting&.booking_changes == true
              SendBookingStatusChangeSmsJob.perform_later(booking.id)
            end
          else
            render json: {
              error: booking.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def get_booking_slots
          business = ::Business.find_by(id: params[:id])
          service = ::Service.find_by(id: params[:service_id])

          unless business && service
            return render json: {
              error: "Business or service not found."
            }, status: :not_found
          end

          date = params[:date].to_date

          slots = BookingAvailability.new(
            business,
            service,
            date
          ).call

          render json: {
            business_id: business.id,
            service_id: service.id,
            date: date,
            slots: slots
          }, status: :ok
        end

        def create

          business = ::Business.find(params[:id])

          user = User.find_or_create_by!(
            email: booking_params[:email]
          ) do |new_user|
            new_user.first_name = booking_params[:first_name]
            new_user.last_name = booking_params[:last_name]
            new_user.phone_number = booking_params[:phone]
            new_user.password = SecureRandom.hex(10)
            new_user.role = :customer
            new_user.terms_accepted = true
          end

          booking = Booking.new(
            business_id: business.id,
            user_id: user.id,
            service_id: booking_params[:service_id],
            date: booking_params[:date],
            time: booking_params[:time]
          )

          if business.business_setting&.automatically_confirm_bookings == true
            booking.status = 'confirmed'
          else
            booking.status = 'pending'
          end

          if booking.save

            render json: {
              success: true,
              booking: {
                id: booking.id,
                business_id: booking.business_id,
                user_id: booking.user_id,
                user_name: "#{user.first_name} #{user.last_name}",
                service_id: booking.service_id,
                date: booking.date,
                time: booking.time,
                status: booking.status
              }
            }, status: :created

          else

            render json: {
              success: false,
              errors: booking.errors.full_messages
            }, status: :unprocessable_entity

          end

        end

        private

        def booking_params
          params
            .require(:booking)
            .permit(
              :service_id,
              :date,
              :time,
              :first_name,
              :last_name,
              :email,
              :phone
            )
        end


      end
    end
  end
end

