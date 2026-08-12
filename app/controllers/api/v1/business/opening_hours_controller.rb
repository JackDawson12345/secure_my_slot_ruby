module Api
  module V1
    module Business
      class OpeningHoursController < ApplicationController

        skip_before_action :verify_authenticity_token


        def get_opening_hours
          business = ::Business.find_by(id: params[:id])

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

              opening_hour = business.opening_hours.find(hour_data[:id])

              opening_hour.update!(
                open: hour_data[:open],
                opens_at: hour_data[:opens_at],
                closes_at: hour_data[:closes_at]
              )


              submitted_break_ids = []

              hour_data[:breaks]&.each do |break_data|

                if break_data[:id].present?

                  opening_break = opening_hour.business_opening_hour_breaks.find(
                    break_data[:id]
                  )

                  opening_break.update!(
                    starts_at: break_data[:starts_at],
                    ends_at: break_data[:ends_at]
                  )

                  submitted_break_ids << opening_break.id

                else

                  new_break = opening_hour.business_opening_hour_breaks.create!(
                    starts_at: break_data[:starts_at],
                    ends_at: break_data[:ends_at]
                  )

                  submitted_break_ids << new_break.id

                end

              end


              # Delete removed breaks
              opening_hour.business_opening_hour_breaks
                          .where.not(id: submitted_break_ids)
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
            error: e.message
          }, status: :unprocessable_entity
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

      end
    end
  end
end

