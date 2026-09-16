# app/controllers/api/v1/business/get_info_controller.rb

module Api
  module V1
    module Business
      class GetInfoController < ApplicationController

        require "net/http"
        require "json"


        def get_businesses
          businesses = ::Business.order(created_at: :desc)

          render json: {
            businesses: businesses.map do |business|
              {
                id: business.id,
                business_name: business.business_name,
                page_address: business.page_address,
                category: business.category,
                phone_number: business.phone_number,
                address: business.address,
                subscribed: business.subscribed,
                created_at: business.created_at,
                updated_at: business.updated_at
              }
            end
          }, status: :ok
        end

        def get_users_business
          user = ::User.find(params[:user_id])
          business = user.business

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          render json: {
            business: {
              id: business.id,
              business_name: business.business_name,
              page_address: business.page_address,
              category: business.category,
              phone_number: business.phone_number,
              address: business.address,
              subscribed: business.subscribed,
              created_at: business.created_at,
              updated_at: business.updated_at
            }
          }, status: :ok
        end

        def get_business
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          render json: {
            business: {
              id: business.id,
              business_name: business.business_name,
              page_address: business.page_address,
              category: business.category,
              phone_number: business.phone_number,
              address: business.address,
              subscribed: business.subscribed,
              created_at: business.created_at,
              updated_at: business.updated_at
            }
          }, status: :ok
        end

        def get_business_settings
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          business_setting = business.business_setting

          unless business_setting
            return render json: {
              error: "Business settings not found."
            }, status: :not_found
          end

          render json: {
            settings: {
              id: business_setting.id,
              business_id: business_setting.business_id,
              business_name: business_setting.business_name,
              business_category: business_setting.business_category,
              phone_number: business_setting.phone_number,
              business_email: business_setting.business_email,
              business_description: business_setting.business_description,
              address: {
                address_line_1: business_setting.address_line_1,
                address_line_2: business_setting.address_line_2,
                town_or_city: business_setting.town_or_city,
                postcode: business_setting.postcode,
                country: business_setting.country,
                latitude: business_setting.latitude,
                longitude: business_setting.longitude
              },
              booking_page_live: business_setting.booking_page_live,
              automatically_confirm_bookings: business_setting.automatically_confirm_bookings,
              allow_customer_cancellations: business_setting.allow_customer_cancellations,
              require_customer_phone_number: business_setting.require_customer_phone_number,
              cancellation_notice_hours: business_setting.cancellation_notice_hours,
              notifications: {
                new_booking_notifications: business_setting.new_booking_notifications,
                cancellation_notifications: business_setting.cancellation_notifications,
                daily_appointment_summary: business_setting.daily_appointment_summary
              },
              created_at: business_setting.created_at,
              updated_at: business_setting.updated_at
            }
          }, status: :ok
        end

        def get_dashboard_details
          @business = ::Business.find(params[:id])

          @bookings = ::Booking
                        .where(business: @business)
                        .where.not(user_id: nil)
                        .includes(:user, :service)

          render json: {
            business: {
              id: @business.id,
              name: @business.business_name
            },
            dashboard: {
              today_bookings: set_today_bookings,
              next_booking: set_next_booking,
              weekly_bookings: set_weekly_bookings,
              customers: set_customers,
              monthly_revenue: set_monthly_revenue
            }
          }, status: :ok
        end

        def get_reviews
          business = ::Business.find_by(id: params[:id])
          settings = business.business_setting
          check_verify_link = settings.check_verify_link

          unless check_verify_link.present?
            return render json: {
              error: "No reviews found."
            }, status: :not_found
          end

          check_verify_slug = URI.parse(check_verify_link).path.split("/").last

          uri = URI("https://www.checkverify.co.uk/api/v1/reviews/user/#{check_verify_slug}")

          response = Net::HTTP.get_response(uri)

          unless response.is_a?(Net::HTTPSuccess)
            return render json: {
              error: "Unable to retrieve reviews."
            }, status: :bad_gateway
          end

          data = JSON.parse(response.body)

          recent_reviews = data["reviews"]
                             .sort_by { |review| Time.parse(review["created_at"]) }
                             .reverse
                             .first(5)

          render json: {
            total_reviews: data.dig("user", "total_reviews"),
            average_rating: data.dig("user", "average_rating").to_f.round(2),
            reviews: recent_reviews
          }
        end

        private

        def set_next_booking
          current_datetime = Time.current

          next_booking = @bookings
                           .where(
                             "date > ? OR (date = ? AND time >= ?)",
                             Date.current,
                             Date.current,
                             Time.current.strftime("%H:%M")
                           )
                           .order(date: :asc, time: :asc)
                           .first

          return nil unless next_booking

          booking_json(next_booking)
        end
        def set_today_bookings
          today_bookings = @bookings
                             .where(date: Date.current)
                             .order(time: :asc)

          today_count = today_bookings.count

          yesterday_count = @bookings
                              .where(date: Date.current.yesterday)
                              .count

          current_seconds = Time.current.seconds_since_midnight

          next_booking = today_bookings.find do |booking|
            booking.time.seconds_since_midnight >= current_seconds
          end

          {
            count: today_count,
            difference: today_count - yesterday_count,
            next_booking: next_booking ? booking_json(next_booking) : nil,
            bookings: today_bookings.map { |booking| booking_json(booking) }
          }
        end
        def set_weekly_bookings
          current_week_range =
            Date.current.beginning_of_week..Date.current.end_of_week

          previous_week_range =
            1.week.ago.to_date.beginning_of_week..
            1.week.ago.to_date.end_of_week

          this_week_count = @bookings
                              .where(date: current_week_range)
                              .count

          previous_week_count = @bookings
                                  .where(date: previous_week_range)
                                  .count

          {
            count: this_week_count,
            percentage_change: percentage_change(
              this_week_count,
              previous_week_count
            )
          }
        end
        def set_customers
          customer_bookings = @bookings.group_by(&:user)

          total_customers = customer_bookings.count

          new_customers = customer_bookings.count do |_user, bookings|
            first_booking = bookings.min_by do |booking|
              [booking.date, booking.time]
            end

            first_booking.present? &&
              first_booking.date >= Date.current.beginning_of_month &&
              first_booking.date <= Date.current.end_of_month
          end

          {
            total: total_customers,
            new_this_month: new_customers
          }
        end
        def set_monthly_revenue
          current_month_range =
            Date.current.beginning_of_month..Date.current.end_of_month

          previous_month_date = 1.month.ago.to_date

          previous_month_range =
            previous_month_date.beginning_of_month..
            previous_month_date.end_of_month

          revenue = confirmed_revenue(current_month_range)

          previous_revenue = confirmed_revenue(previous_month_range)

          {
            amount: revenue,
            percentage_change: percentage_change(
              revenue,
              previous_revenue
            )
          }
        end
        def confirmed_revenue(date_range)
          @bookings
            .where(date: date_range, status: "confirmed")
            .sum do |booking|
            booking.service&.price.to_d
          end
        end
        def percentage_change(current_value, previous_value)
          return 0 if previous_value.to_d.zero?

          (
            ((current_value.to_d - previous_value.to_d) /
              previous_value.to_d) * 100
          ).round
        end
        def booking_json(booking)
          {
            id: booking.id,
            customer: {
              id: booking.user.id,
              name: "#{booking.user.first_name} #{booking.user.last_name}"
            },
            service: booking.service&.name,
            date: booking.date,
            time: booking.time,
            status: booking.status
          }
        end

        def authenticate_api_key!
          provided_api_key = request.headers["X-API-Key"]
          expected_api_key = ENV["SECURE_MY_SLOT_API_KEY"].presence ||
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