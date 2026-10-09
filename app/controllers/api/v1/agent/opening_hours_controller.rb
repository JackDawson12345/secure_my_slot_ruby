
module Api
  module V1
    module Agent
      class OpeningHoursController < Api::V1::BaseController

        before_action :authenticate_api_key!
        before_action :authenticate_agent!
        before_action :set_business_agent!

        # ================================================
        # GET /api/v1/agent/:id/opening-hours
        # ================================================

        def index
          opening_hours = @business.opening_hours
                                   .includes(:breaks)
                                   .sort_by(&:day_of_week_before_type_cast)

          booking_setting = @business.booking_setting

          open_days = opening_hours.select(&:open?)

          render json: {
            success: true,
            message: "Opening hours loaded successfully.",

            business: {
              id: @business.id,
              business_name: @business.business_name
            },

            opening_hours: opening_hours.map do |opening_hour|
              opening_hour_json(opening_hour)
            end,

            booking_settings: booking_setting.present? ? {
              booking_interval_minutes:
                booking_setting.booking_interval_minutes,

              minimum_notice_minutes:
                booking_setting.minimum_notice_minutes,

              advance_booking_days:
                booking_setting.advance_booking_days,

              buffer_minutes:
                booking_setting.buffer_minutes
            } : nil,

            weekly_summary: {
              total_days: opening_hours.count,
              open_days: open_days.count,
              closed_days: opening_hours.count - open_days.count,

              days: opening_hours.map do |opening_hour|
                {
                  day_of_week: opening_hour.day_of_week,
                  day_name: opening_hour.day_name,
                  open: opening_hour.open?
                }
              end
            },

            permissions: {
              can_view: true,
              can_edit: false
            }

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
          return if performed?

          unless current_user && current_user.role.to_s == "agent"
            return render json: {
              success: false,
              error: "Agent authentication required"
            }, status: :unauthorized
          end

          unless params[:id].to_s == current_user.id.to_s
            return render json: {
              success: false,
              error: "You cannot access another agent's opening hours"
            }, status: :forbidden
          end
        end

        # ================================================
        # FIND AGENT'S BUSINESS
        # ================================================

        def set_business_agent!
          return if performed?

          memberships = ::BusinessAgent.where(
            user_id: current_user.id,
            status: "active"
          )

          if params[:business_id].present?
            memberships = memberships.where(
              business_id: params[:business_id]
            )
          elsif memberships.count > 1
            return render json: {
              success: false,
              error: "Please specify a business_id."
            }, status: :unprocessable_entity
          end

          @business_agent = memberships.first

          unless @business_agent
            return render json: {
              success: false,
              error: "Active business agent relationship not found."
            }, status: :not_found
          end

          @business = ::Business.find_by(
            id: @business_agent.business_id
          )

          unless @business
            return render json: {
              success: false,
              error: "Business not found."
            }, status: :not_found
          end
        end

        # ================================================
        # OPENING HOUR JSON
        # ================================================

        def opening_hour_json(opening_hour)
          {
            id: opening_hour.id,

            day_of_week: opening_hour.day_of_week,
            day_name: opening_hour.day_name,

            open: opening_hour.open?,

            opens_at: format_time(opening_hour.opens_at),
            closes_at: format_time(opening_hour.closes_at),

            hours_set: (
              opening_hour.opens_at.present? &&
                opening_hour.closes_at.present?
            ),

            breaks: (
              if opening_hour.open?
                opening_hour.breaks.filter_map do |break_record|
                  next unless break_record.starts_at.present? &&
                              break_record.ends_at.present?

                  {
                    id: break_record.id,

                    starts_at: format_time(
                      break_record.starts_at
                    ),

                    ends_at: format_time(
                      break_record.ends_at
                    )
                  }
                end
              else
                []
              end
            )
          }
        end

        # ================================================
        # FORMAT TIME
        # ================================================

        def format_time(time)
          time&.strftime("%H:%M")
        end

      end
    end
  end
end
