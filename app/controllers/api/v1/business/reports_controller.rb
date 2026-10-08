module Api
  module V1
    module Business
      class ReportsController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authenticate_user!
        before_action :set_business

        def get_reports
          bookings = @business.bookings
          services = @business.services
          staff = @business.agents
          page_views = @business.page_views

          render json: {
            overview: overview_report(bookings, page_views),
            bookings: booking_report(bookings),
            customers: customer_report(bookings, page_views),
            services: service_report(bookings, services),
            staff: staff_report(bookings, staff),
            website: website_report(bookings, page_views)
          }, status: :ok
        end

        private

        def set_business
          @business = current_user.business

          unless @business && @business.id.to_s == params[:id].to_s
            render json: {
              error: "Business not found"
            }, status: :not_found
          end
        end

        # =========================================================
        # OVERVIEW
        # =========================================================

        def overview_report(bookings, page_views)
          total_amount = bookings.sum(:amount)

          conversion_rate =
            if page_views.count.positive?
              (bookings.count.to_f / page_views.count.to_f) * 100
            else
              0
            end

          {
            total_bookings: bookings.count,
            total_revenue: total_amount.to_f,
            total_customers: bookings.distinct.count(:user_id),
            page_views: page_views.count,
            conversion_rate: conversion_rate.round(1)
          }
        end

        # =========================================================
        # BOOKINGS
        # =========================================================

        def booking_report(bookings)
          pending = bookings.where(status: "pending").count
          confirmed = bookings.where(status: "confirmed").count
          completed = bookings.where(status: "completed").count
          cancelled = bookings.where(status: "cancelled").count

          days = %w[
            Monday
            Tuesday
            Wednesday
            Thursday
            Friday
            Saturday
            Sunday
          ]

          booking_counts =
            bookings.group_by do |booking|
              booking.date.strftime("%A")
            end.transform_values(&:count)

          bookings_by_day = days.map do |day|
            {
              day: day,
              count: booking_counts[day] || 0
            }
          end

          heatmap_hours = [
            9,
            11,
            13,
            15,
            17,
            19
          ]

          heatmap = days.map do |day|
            bookings_for_day = bookings.select do |booking|
              booking.date.strftime("%A") == day
            end

            {
              day: day,
              hours: heatmap_hours.map do |hour|
                {
                  hour: hour,
                  count: bookings_for_day.count do |booking|
                    booking.time.hour.between?(hour, hour + 1)
                  end
                }
              end
            }
          end

          service_counts =
            bookings
              .group(:service_id)
              .count
              .sort_by { |_service_id, count| -count }

          services =
            Service
              .where(id: service_counts.map(&:first))
              .index_by(&:id)

          total_bookings =
            service_counts.sum do |_service_id, count|
              count
            end

          popular_services =
            service_counts.filter_map do |service_id, count|
              service = services[service_id]

              next unless service

              {
                id: service.id,
                name: service.name,
                count: count,
                percentage:
                  total_bookings.positive? ?
                    ((count.to_f / total_bookings) * 100).round :
                    0
              }
            end

          {
            total: bookings.count,

            status: {
              pending: pending,
              confirmed: confirmed,
              completed: completed,
              cancelled: cancelled
            },

            by_day: bookings_by_day,

            heatmap: heatmap,

            popular_services: popular_services
          }
        end

        # =========================================================
        # CUSTOMERS
        # =========================================================

        def customer_report(bookings, page_views)
          user_ids =
            bookings
              .where.not(user_id: nil)
              .select(:user_id)
              .distinct

          users = User.where(id: user_ids)

          booking_counts =
            bookings
              .where.not(user_id: nil)
              .group(:user_id)
              .count

          new_customers =
            booking_counts.count do |_user_id, count|
              count == 1
            end

          returning_customers =
            booking_counts.count do |_user_id, count|
              count > 1
            end

          total_customers =
            new_customers + returning_customers

          new_percentage =
            percentage(
              new_customers,
              total_customers
            )

          returning_percentage =
            percentage(
              returning_customers,
              total_customers
            )

          business_created_at = @business.created_at

          months_active =
            (
              (Time.current.year * 12 + Time.current.month) -
                (
                  business_created_at.year * 12 +
                    business_created_at.month
                )
            ) + 1

          average_page_views_per_month =
            (
              page_views.count.to_f /
                months_active
            ).round(1)

          top_customers =
            users
              .joins(:bookings)
              .where(
                bookings: {
                  business_id: @business.id
                }
              )
              .group("users.id")
              .order(
                Arel.sql(
                  "COUNT(bookings.id) DESC"
                )
              )
              .limit(5)
              .select(
                "users.*, COUNT(bookings.id) AS bookings_count"
              )
              .map do |user|
              {
                id: user.id,
                first_name: user.first_name,
                last_name: user.last_name,
                email: user.email,
                bookings_count: user.bookings_count.to_i
              }
            end

          six_months_ago =
            5.months.ago.beginning_of_month

          first_bookings =
            bookings
              .where.not(user_id: nil)
              .group(:user_id)
              .minimum(:created_at)

          growth = 6.times.map do |i|
            month = six_months_ago + i.months

            count =
              first_bookings.count do |_user_id, first_booking_date|
                first_booking_date >= month.beginning_of_month &&
                  first_booking_date <= month.end_of_month
              end

            {
              label: month.strftime("%b"),
              count: count
            }
          end

          {
            total: total_customers,

            new_customers: {
              count: new_customers,
              percentage: new_percentage
            },

            returning_customers: {
              count: returning_customers,
              percentage: returning_percentage
            },

            average_page_views_per_month:
              average_page_views_per_month,

            top_customers: top_customers,

            growth: growth
          }
        end

        # =========================================================
        # SERVICES
        # =========================================================

        def service_report(bookings, services)
          booking_counts =
            bookings
              .group(:service_id)
              .count

          most_booked_service_id =
            booking_counts
              .max_by { |_service_id, count| count }
              &.first

          most_booked_service =
            services.find_by(
              id: most_booked_service_id
            )

          average_service_cost =
            services.average(:price)&.round(2) || 0

          average_service_duration =
            services
              .average(:minutes_duration)
              &.round || 0

          revenue_totals =
            bookings
              .group(:service_id)
              .sum(:amount)

          service_data =
            services.map do |service|
              {
                id: service.id,
                name: service.name,
                booking_count:
                  booking_counts.fetch(
                    service.id,
                    0
                  ),
                revenue:
                  revenue_totals.fetch(
                    service.id,
                    0
                  ).to_f,
                minutes_duration: service.minutes_duration,
              }
            end

          max_revenue =
            service_data
              .map { |item| item[:revenue] }
              .max || 0

          service_data.each do |item|
            item[:percentage] =
              if max_revenue.positive?
                (
                  item[:revenue].to_f /
                    max_revenue *
                    100
                ).round
              else
                0
              end
          end

          service_data.sort_by! do |item|
            -item[:revenue]
          end

          {
            total_services: services.count,

            most_booked_service:
              if most_booked_service
                {
                  id: most_booked_service.id,
                  name: most_booked_service.name,
                  bookings:
                    booking_counts.fetch(
                      most_booked_service.id,
                      0
                    )
                }
              end,

            average_service_cost:
              average_service_cost.to_f,

            average_service_duration:
              average_service_duration,

            booking_chart:
              services.map do |service|
                {
                  id: service.id,
                  name: service.name,
                  bookings:
                    booking_counts.fetch(
                      service.id,
                      0
                    )
                }
              end,

            revenue: service_data
          }
        end

        # =========================================================
        # STAFF
        # =========================================================

        def staff_report(bookings, staff)
          average_bookings =
            if staff.any?
              (
                bookings.count.to_f /
                  staff.count
              ).round(1)
            else
              0
            end

          completed_appointments =
            bookings
              .where(status: "completed")
              .count

          staff_data =
            staff.map do |agent|
              agent_bookings =
                bookings.where(
                  agent_id: agent.id
                )

              completed_bookings =
                agent_bookings.where(
                  status: "completed"
                )

              revenue =
                agent_bookings.sum(:amount)

              total_minutes =
                agent_bookings
                  .joins(:service)
                  .sum(
                    "services.minutes_duration"
                  )

              {
                id: agent.id,
                first_name: agent.first_name,
                last_name: agent.last_name,
                name:
                  "#{agent.first_name} #{agent.last_name}",

                bookings:
                  agent_bookings.count,

                completed:
                  completed_bookings.count,

                revenue:
                  revenue.to_f,

                minutes_worked:
                  total_minutes.to_i
              }
            end

          {
            total_agents:
              staff.count,

            completed_appointments:
              completed_appointments,

            average_bookings_per_agent:
              average_bookings,

            agents:
              staff_data
          }
        end

        # =========================================================
        # WEBSITE
        # =========================================================

        def website_report(bookings, page_views)
          total_page_views =
            page_views.count

          unique_visitors =
            page_views
              .where.not(
              visitor_id: [nil, ""]
            )
              .distinct
              .count(:visitor_id)

          booking_conversion =
            percentage(
              bookings.count,
              total_page_views
            )

          views_per_visitor =
            if unique_visitors.positive?
              (
                total_page_views.to_f /
                  unique_visitors
              ).round(1)
            else
              0
            end

          traffic_months =
            (0..5)
              .map do |i|
              i.months.ago.beginning_of_month
            end
              .reverse

          traffic =
            traffic_months.map do |month|
              {
                label: month.strftime("%b"),

                visitors:
                  page_views
                    .where(
                      created_at:
                        month.beginning_of_month..
                          month.end_of_month
                    )
                    .where.not(
                    visitor_id: [nil, ""]
                  )
                    .distinct
                    .count(:visitor_id)
              }
            end

          traffic_sources =
            page_views
              .where.not(
              traffic_source: [nil, ""]
            )
              .group(:traffic_source)
              .count

          tracked_source_views =
            traffic_sources.values.sum

          sources = {
            google: source_data(
              traffic_sources["google"],
              tracked_source_views
            ),

            direct: source_data(
              traffic_sources["direct"],
              tracked_source_views
            ),

            social: source_data(
              traffic_sources["social"],
              tracked_source_views
            ),

            referral: source_data(
              traffic_sources["referral"],
              tracked_source_views
            ),

            other: source_data(
              traffic_sources["other"],
              tracked_source_views
            )
          }

          device_counts =
            page_views
              .where.not(
              device_type: [nil, ""]
            )
              .group(:device_type)
              .count

          tracked_device_views =
            device_counts.values.sum

          devices = {
            mobile: source_data(
              device_counts["mobile"],
              tracked_device_views
            ),

            desktop: source_data(
              device_counts["desktop"],
              tracked_device_views
            ),

            tablet: source_data(
              device_counts["tablet"],
              tracked_device_views
            )
          }

          visitor_counts =
            page_views
              .where.not(
              visitor_id: [nil, ""]
            )
              .group(:visitor_id)
              .count

          new_visitors =
            visitor_counts.count do |_visitor_id, count|
              count == 1
            end

          returning_visitors =
            visitor_counts.count do |_visitor_id, count|
              count > 1
            end

          {
            total_page_views: total_page_views,
            unique_visitors: unique_visitors,
            booking_count: bookings.count,
            booking_conversion:
              booking_conversion,
            views_per_visitor:
              views_per_visitor,

            traffic: traffic,

            traffic_sources: sources,

            devices: devices,

            visitors: {
              new: {
                count: new_visitors,
                percentage:
                  percentage(
                    new_visitors,
                    unique_visitors
                  )
              },

              returning: {
                count: returning_visitors,
                percentage:
                  percentage(
                    returning_visitors,
                    unique_visitors
                  )
              }
            }
          }
        end

        # =========================================================
        # HELPERS
        # =========================================================

        def source_data(value, total)
          value = value.to_i

          {
            count: value,
            percentage: percentage(value, total)
          }
        end

        def percentage(value, total)
          return 0 if total.to_i.zero?

          (
            value.to_f /
              total.to_f *
              100
          ).round(1)
        end
      end
    end
  end
end