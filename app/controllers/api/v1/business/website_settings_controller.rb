module Api
  module V1
    module Business
      class WebsiteSettingsController < ApplicationController

        skip_before_action :verify_authenticity_token

        def show
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          website_setting = business.business_website

          unless website_setting
            return render json: {
              error: "Website settings not found."
            }, status: :not_found
          end

          render json: {
            settings: website_settings_json(website_setting)
          }, status: :ok
        end


        def update
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          website_setting = business.business_website

          unless website_setting
            return render json: {
              error: "Website settings not found."
            }, status: :not_found
          end

          website_setting.update!(website_settings_params)

          render json: {
            message: "Website settings updated successfully",
            settings: website_settings_json(website_setting)
          }, status: :ok

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end


        private

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

        def website_settings_params
          params.require(:settings).permit(
            :colour,

            hero: [
              :title,
              :sentence,
              info_boxes: [
                :icon,
                :title
              ]
            ],

            services: [
              :title,
              :sentence
            ],

            about_us: [
              :title,
              :paragraph,
              icon_boxes: [
                :title,
                :sentence
              ]
            ],

            visit: [
              :title,
              :sentence
            ]
          )
        end


        def website_settings_json(website_setting)
          {
            id: website_setting.id,
            business_id: website_setting.business_id,
            colour: website_setting.colour,
            hero: normalise_jsonb(website_setting.hero),
            services: normalise_jsonb(website_setting.services),
            about_us: normalise_jsonb(website_setting.about_us),
            visit: normalise_jsonb(website_setting.visit),
            created_at: website_setting.created_at,
            updated_at: website_setting.updated_at
          }
        end


        def normalise_jsonb(value)
          return value unless value.is_a?(String)

          JSON.parse(value)
        rescue JSON::ParserError
          begin
            JSON.parse(value.gsub("=>", ":"))
          rescue JSON::ParserError
            value
          end
        end

      end
    end
  end
end