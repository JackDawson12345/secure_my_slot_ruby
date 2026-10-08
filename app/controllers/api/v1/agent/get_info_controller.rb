
module Api
  module V1
    module Agent
      class GetInfoController < Api::V1::BaseController

        skip_before_action :verify_authenticity_token
        before_action :authenticate_api_key!

        # ================================================
        # GET AGENT DASHBOARD DETAILS
        # ================================================

        def get_dashboard_details

          # ----------------------------------------------
          # Find agent
          # ----------------------------------------------

          agent = ::User.find_by(id: params[:id])

          unless agent && agent.role.to_s == "agent"
            return render json: {
              error: "Agent not found."
            }, status: :not_found
          end

          # ----------------------------------------------
          # Find active business agent relationship
          # ----------------------------------------------

          memberships = ::BusinessAgent
                          .where(user_id: agent.id, status: "active")

          # If the agent works for multiple businesses,
          # require an explicit business ID.
          if params[:business_id].present?
            memberships = memberships.where(
              business_id: params[:business_id]
            )
          elsif memberships.count > 1
            return render json: {
              error: "Please specify a business_id."
            }, status: :unprocessable_entity
          end

          business_agent = memberships.first

          unless business_agent
            return render json: {
              error: "Active business agent relationship not found."
            }, status: :not_found
          end

          # ----------------------------------------------
          # Get business
          # ----------------------------------------------

          business = ::Business.find_by(
            id: business_agent.business_id
          )

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          # ----------------------------------------------
          # Get business agent settings
          # ----------------------------------------------

          business_agent_settings =
            ::BusinessAgentSetting.find_by(
              business_id: business.id
            )

          booking_visibility =
            business_agent_settings&.booking_visibility ||
            "mine"

          # ----------------------------------------------
          # Apply booking visibility
          # ----------------------------------------------

          bookings = business.bookings

          unless booking_visibility == "all_bookings"
            bookings = bookings.where(
              agent_id: agent.id
            )
          end

          # ----------------------------------------------
          # Dates
          # ----------------------------------------------

          today = Date.current

          # ----------------------------------------------
          # Today's bookings
          # ----------------------------------------------

          today_bookings = bookings
                             .where(date: today)
                             .where.not(
            status: %w[cancelled canceled]
          )
                             .includes(:user, :service)
                             .order(:time)

          today_bookings_count =
            today_bookings.size

          # ----------------------------------------------
          # This week's bookings
          # ----------------------------------------------

          this_week_bookings_count = bookings
                                       .where(
                                         date: today.beginning_of_week..
                                           today.end_of_week
                                       )
                                       .where.not(
            status: %w[cancelled canceled]
          )
                                       .count

          # ----------------------------------------------
          # Completed bookings this month
          # ----------------------------------------------

          completed_bookings_count = bookings
                                       .where(status: "completed")
                                       .where(
                                         date: today.beginning_of_month..
                                           today.end_of_month
                                       )
                                       .count

          # ----------------------------------------------
          # Upcoming bookings
          # ----------------------------------------------

          upcoming_bookings_count = bookings
                                      .where(date: today..)
                                      .where.not(
            status: %w[
                cancelled
                canceled
                completed
              ]
          )
                                      .count

          # ----------------------------------------------
          # Next booking today
          # ----------------------------------------------

          # Match the time-of-day comparison used by
          # the web dashboard.
          next_booking = today_bookings
                           .where("time >= ?", Time.current)
                           .first

          # ----------------------------------------------
          # JSON response
          # ----------------------------------------------

          render json: {

            message: "Agent dashboard loaded.",

            agent: {
              id: agent.id,
              first_name: agent.first_name,
              last_name: agent.last_name,
              name: [
                agent.first_name,
                agent.last_name
              ].compact.join(" ").presence || agent.email,
              email: agent.email,
              role: agent.role
            },

            business: {
              id: business.id,
              business_name: business.business_name,
              phone_number: business.phone_number,
              email: business.email
            },

            settings: {
              booking_visibility: booking_visibility,
              can_view_all_bookings:
                booking_visibility == "all_bookings"
            },

            today_bookings: {
              count: today_bookings_count,
              bookings: today_bookings.map do |booking|
                booking_json(booking)
              end
            },

            this_week_bookings: {
              count: this_week_bookings_count
            },

            completed_bookings: {
              count: completed_bookings_count
            },

            upcoming_bookings: {
              count: upcoming_bookings_count
            },

            next_booking: next_booking.present? ?
                            booking_json(next_booking) : nil

          }, status: :ok

        end

        private

        # ================================================
        # BOOKING JSON
        # ================================================

        def booking_json(booking)

          customer = booking.user

          customer_name = [
            customer&.first_name,
            customer&.last_name
          ].compact.join(" ")

          if customer_name.blank?
            customer_name =
              customer&.email&.split("@")&.first&.titleize ||
              "Customer"
          end

          {
            id: booking.id,
            date: booking.date,
            time: booking.time&.strftime("%H:%M"),
            formatted_time:
              booking.time&.strftime("%-I:%M %P"),
            status: booking.status,

            customer: {
              id: customer&.id,
              first_name: customer&.first_name,
              last_name: customer&.last_name,
              name: customer_name,
              email: customer&.email
            },

            service: {
              id: booking.service&.id,
              name: booking.service&.name
            }
          }

        end

        # ================================================
        # API KEY AUTHENTICATION
        # ================================================

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
