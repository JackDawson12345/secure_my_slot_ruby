module Api
  module V1
    module Business
      class OpeningHoursController < ApplicationController

        skip_before_action :verify_authenticity_token


        def get_opening_hours
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          opening_hours = business.opening_hours

          breaks = BusinessOpeningHourBreak.where(
            business_opening_hour_id: opening_hours.pluck(:id)
          )

          render json: {
            opening_hours: opening_hours.map do |opening_hour|
              {
                id: opening_hour.id,
                business_id: opening_hour.business_id,
                day_of_week: opening_hour.day_of_week,
                open: opening_hour.open,
                opens_at: opening_hour.opens_at&.strftime("%H:%M"),
                closes_at: opening_hour.closes_at&.strftime("%H:%M"),

                breaks: breaks.where(
                  business_opening_hour_id: opening_hour.id
                ).map do |opening_break|
                  {
                    id: opening_break.id,
                    starts_at: opening_break.starts_at.strftime("%H:%M"),
                    ends_at: opening_break.ends_at.strftime("%H:%M")
                  }
                end,

                created_at: opening_hour.created_at,
                updated_at: opening_hour.updated_at
              }
            end
          }, status: :ok
        end


        def update_opening_hours
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end

          ActiveRecord::Base.transaction do

            opening_hours_params.each do |hour_data|

              opening_hour =
                business.opening_hours.find(
                  hour_data[:id]
                )

              opening_hour.update!(
                open: hour_data[:open],
                opens_at: hour_data[:opens_at],
                closes_at: hour_data[:closes_at]
              )


              submitted_break_ids = []


              hour_data[:breaks]&.each do |break_data|

                if break_data[:id].present?

                  opening_break =
                    opening_hour
                      .business_opening_hour_breaks
                      .find(
                        break_data[:id]
                      )

                  opening_break.update!(
                    starts_at: break_data[:starts_at],
                    ends_at: break_data[:ends_at]
                  )

                  submitted_break_ids <<
                    opening_break.id

                else

                  new_break =
                    opening_hour
                      .business_opening_hour_breaks
                      .create!(
                        starts_at: break_data[:starts_at],
                        ends_at: break_data[:ends_at]
                      )

                  submitted_break_ids <<
                    new_break.id

                end

              end


              opening_hour
                .business_opening_hour_breaks
                .where.not(
                id: submitted_break_ids
              )
                .destroy_all

            end

          end


          render json: {
            message: "Opening hours updated successfully"
          }, status: :ok


        rescue ActiveRecord::RecordNotFound

          render json: {
            error: "Opening hour or break not found"
          }, status: :not_found


        rescue ActiveRecord::RecordInvalid => e

          render json: {
            error: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end


        # ==========================================
        # BLOCKED TIMES
        # ==========================================


        def get_blocked_times
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end


          blocked_times =
            business
              .business_blocked_times
              .order(
                starts_at: :asc
              )


          render json: {
            blocked_times: blocked_times.map do |blocked_time|
              blocked_time_json(
                blocked_time
              )
            end
          }, status: :ok
        end


        def create_blocked_time
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end


          blocked_time =
            business
              .business_blocked_times
              .new(
                blocked_time_params
              )


          normalise_blocked_time(
            blocked_time
          )


          if blocked_time.save

            render json: {
              message: "Blocked time added successfully",

              blocked_time:
                blocked_time_json(
                  blocked_time
                )
            }, status: :created

          else

            render json: {
              error: "Unable to add blocked time",

              errors:
                blocked_time
                  .errors
                  .full_messages
            }, status: :unprocessable_entity

          end
        end


        def update_blocked_time
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end


          blocked_time =
            business
              .business_blocked_times
              .find_by(
                id: params[:blocked_time_id]
              )


          unless blocked_time
            return render json: {
              error: "Blocked time not found"
            }, status: :not_found
          end


          blocked_time.assign_attributes(
            blocked_time_params
          )


          normalise_blocked_time(
            blocked_time
          )


          if blocked_time.save

            render json: {
              message: "Blocked time updated successfully",

              blocked_time:
                blocked_time_json(
                  blocked_time
                )
            }, status: :ok

          else

            render json: {
              error: "Unable to update blocked time",

              errors:
                blocked_time
                  .errors
                  .full_messages
            }, status: :unprocessable_entity

          end
        end


        def delete_blocked_time
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found"
            }, status: :not_found
          end


          blocked_time =
            business
              .business_blocked_times
              .find_by(
                id: params[:blocked_time_id]
              )


          unless blocked_time
            return render json: {
              error: "Blocked time not found"
            }, status: :not_found
          end


          blocked_time.destroy!


          render json: {
            message: "Blocked time removed successfully"
          }, status: :ok
        end


        private


        def opening_hours_params
          params.require(:opening_hours)
                .map do |hour|

            hour.permit(
              :id,
              :open,
              :opens_at,
              :closes_at,

              breaks: [
                :id,
                :starts_at,
                :ends_at
              ]
            )

          end
        end


        def blocked_time_params
          params
            .require(:business_blocked_time)
            .permit(
              :title,
              :date,
              :end_date,
              :start_time,
              :end_time,
              :all_day,
              :notes
            )
        end


        def normalise_blocked_time(blocked_time)

          start_date =
            parse_date(
              params.dig(
                :business_blocked_time,
                :date
              )
            )


          end_date =
            parse_date(
              params.dig(
                :business_blocked_time,
                :end_date
              )
            ) || start_date


          return if start_date.blank?


          all_day =
            ActiveModel::Type::Boolean
              .new
              .cast(
                params.dig(
                  :business_blocked_time,
                  :all_day
                )
              )


          if all_day

            blocked_time.starts_at =
              Time.zone.local(
                start_date.year,
                start_date.month,
                start_date.day
              ).beginning_of_day


            blocked_time.ends_at =
              Time.zone.local(
                end_date.year,
                end_date.month,
                end_date.day
              ).end_of_day

          else

            blocked_time.starts_at =
              combine_date_and_time(
                start_date,
                params.dig(
                  :business_blocked_time,
                  :start_time
                )
              )


            blocked_time.ends_at =
              combine_date_and_time(
                end_date,
                params.dig(
                  :business_blocked_time,
                  :end_time
                )
              )

          end
        end


        def parse_date(value)

          return if value.blank?

          Date.iso8601(
            value
          )

        rescue Date::Error

          nil

        end


        def combine_date_and_time(
          date,
          time_value
        )

          return if (
            date.blank? ||
              time_value.blank?
          )


          parsed_time =
            Time.zone.parse(
              time_value
            )


          return if parsed_time.blank?


          Time.zone.local(
            date.year,
            date.month,
            date.day,
            parsed_time.hour,
            parsed_time.min
          )
        end


        def blocked_time_json(blocked_time)

          {
            id: blocked_time.id,

            business_id:
              blocked_time.business_id,

            title:
              blocked_time.title,

            all_day:
              blocked_time.all_day,

            date:
              blocked_time
                .starts_at
                &.to_date
                &.iso8601,

            end_date:
              blocked_time
                .ends_at
                &.to_date
                &.iso8601,

            start_time:
              blocked_time.all_day? ?
                nil :
                blocked_time
                  .starts_at
                  &.strftime("%H:%M"),

            end_time:
              blocked_time.all_day? ?
                nil :
                blocked_time
                  .ends_at
                  &.strftime("%H:%M"),

            starts_at:
              blocked_time.starts_at,

            ends_at:
              blocked_time.ends_at,

            notes:
              blocked_time.notes,

            created_at:
              blocked_time.created_at,

            updated_at:
              blocked_time.updated_at
          }
        end

      end
    end
  end
end