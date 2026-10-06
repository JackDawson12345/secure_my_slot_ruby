module Api
  module V1
    module Business
      class WebsiteSettingsController < ApplicationController
        skip_before_action :verify_authenticity_token

        before_action :set_business
        before_action :set_business_website

        # ==========================================
        # GET WEBSITE SETTINGS
        # ==========================================

        def show
          render json: website_settings_response,
                 status: :ok
        end

        # ==========================================
        # UPDATE WEBSITE CONTENT
        # Pro Plus
        # ==========================================

        def update_content
          unless @business.feature_enabled?(:website_content)
            return render json: {
              error: "Upgrade to Pro Plus to edit website content."
            }, status: :forbidden
          end

          settings = website_content_params

          normalise_nested_boxes!(settings)

          @business_website.update!(settings)

          render json: {
            message: "Website content updated successfully",
            settings: website_settings_json
          }, status: :ok

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        # ==========================================
        # UPDATE WEBSITE COLOUR
        # Pro / Pro Plus
        # ==========================================

        def update_colour
          unless @business.feature_enabled?(:website_colour)
            return render json: {
              error: "Upgrade to Pro to customise your website colours."
            }, status: :forbidden
          end

          settings = website_colour_params

          if settings[:colour] == "custom"
            custom_colour =
              settings.delete(:custom_colour)

            save_custom_colour(custom_colour)
          else
            @business_website
              .website_settings_colour
              &.destroy

            settings.delete(:custom_colour)
          end

          @business_website.update!(settings)

          render json: {
            message: "Website colours updated successfully",
            settings: website_settings_json
          }, status: :ok

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        # ==========================================
        # GENERATE CUSTOM COLOUR PALETTE
        # ==========================================

        def generate_colours
          unless @business.feature_enabled?(:website_colour)
            return render json: {
              error: "Upgrade to Pro to customise your website colours."
            }, status: :forbidden
          end

          colour = params.require(:colour)

          generated_colours =
            ColourPaletteGenerator
              .new(colour)
              .generate

          render json: {
            colour: colour,
            palette: generated_colours
          }, status: :ok
        end

        # ==========================================
        # ADD GALLERY IMAGES
        # Pro / Pro Plus
        # ==========================================

        def update_gallery
          unless @business.feature_enabled?(:website_gallery)
            return render json: {
              error: "Upgrade to Pro to use the website gallery."
            }, status: :forbidden
          end

          images = params[:gallery_images]

          unless images.present?
            return render json: {
              error: "No gallery images supplied."
            }, status: :unprocessable_entity
          end

          images = [images] unless images.is_a?(Array)

          current_count =
            @business_website
              .gallery_images
              .count

          if current_count + images.count > 20
            return render json: {
              error: "You can upload a maximum of 20 gallery images."
            }, status: :unprocessable_entity
          end

          @business_website
            .gallery_images
            .attach(images)

          render json: {
            message: "Gallery updated successfully",
            gallery: gallery_json
          }, status: :ok
        end

        # ==========================================
        # DELETE GALLERY IMAGE
        # ==========================================

        def destroy_gallery_image
          unless @business.feature_enabled?(:website_gallery)
            return render json: {
              error: "Upgrade to Pro to use the website gallery."
            }, status: :forbidden
          end

          image =
            @business_website
              .gallery_images
              .find_by(id: params[:image_id])

          unless image
            return render json: {
              error: "Gallery image not found."
            }, status: :not_found
          end

          image.purge

          render json: {
            message: "Gallery image removed successfully",
            gallery: gallery_json
          }, status: :ok
        end

        private

        # ==========================================
        # BUSINESS
        # ==========================================

        def set_business
          @business =
            ::Business.find_by(
              id: params[:id]
            )

          return if @business

          render json: {
            error: "Business not found."
          }, status: :not_found
        end

        # ==========================================
        # WEBSITE
        # ==========================================

        def set_business_website
          return unless @business

          @business_website =
            @business.business_website

          return if @business_website

          render json: {
            error: "Website settings not found."
          }, status: :not_found
        end

        # ==========================================
        # CONTENT PARAMS
        # ==========================================

        def website_content_params
          params
            .require(:settings)
            .permit(
              :hero_image,
              :about_image,

              hero: [
                :title,
                :sentence,
                {
                  info_boxes: {}
                }
              ],

              services: [
                :title,
                :sentence
              ],

              about_us: [
                :title,
                :paragraph,
                {
                  icon_boxes: {}
                }
              ],

              visit: [
                :title,
                :sentence
              ]
            )
            .to_h
        end

        # ==========================================
        # COLOUR PARAMS
        # ==========================================

        def website_colour_params
          params
            .require(:settings)
            .permit(
              :colour,
              :custom_colour
            )
            .to_h
            .symbolize_keys
        end

        # ==========================================
        # NORMALISE BOXES
        # ==========================================

        def normalise_nested_boxes!(permitted)
          hero_boxes =
            permitted.dig(
              "hero",
              "info_boxes"
            )

          if hero_boxes.is_a?(Hash)
            permitted["hero"]["info_boxes"] =
              hero_boxes
                .sort_by do |index, _values|
                index.to_i
              end
                .map(&:last)
          end

          about_boxes =
            permitted.dig(
              "about_us",
              "icon_boxes"
            )

          if about_boxes.is_a?(Hash)
            permitted["about_us"]["icon_boxes"] =
              about_boxes
                .sort_by do |index, _values|
                index.to_i
              end
                .map(&:last)
          end
        end

        # ==========================================
        # SAVE CUSTOM COLOUR
        # ==========================================

        def save_custom_colour(hex_code)
          return if hex_code.blank?

          generated_colours =
            ColourPaletteGenerator
              .new(hex_code)
              .generate

          colour_settings =
            WebsiteSettingsColour
              .find_or_initialize_by(
                business_website:
                  @business_website
              )

          colour_settings.update!(
            business: @business,
            hex_code: hex_code,

            colour_950:
              generated_colours["950"],

            colour_900:
              generated_colours["900"],

            colour_800:
              generated_colours["800"],

            colour_700:
              generated_colours["700"],

            colour_600:
              generated_colours["600"],

            colour_500:
              generated_colours["500"],

            colour_400:
              generated_colours["400"],

            colour_300:
              generated_colours["300"],

            colour_200:
              generated_colours["200"],

            colour_100:
              generated_colours["100"],

            colour_50:
              generated_colours["50"]
          )
        end

        # ==========================================
        # COMPLETE RESPONSE
        # ==========================================

        def website_settings_response
          {
            settings: website_settings_json,

            features: {
              website_content:
                @business.feature_enabled?(
                  :website_content
                ),

              website_colour:
                @business.feature_enabled?(
                  :website_colour
                ),

              website_gallery:
                @business.feature_enabled?(
                  :website_gallery
                )
            },

            options: {
              colours: colour_options,
              icons: icon_options,
              gallery_limit: 20
            }
          }
        end

        # ==========================================
        # SETTINGS JSON
        # ==========================================

        def website_settings_json
          {
            id:
              @business_website.id,

            business_id:
              @business_website.business_id,

            colour:
              @business_website.colour,

            custom_colour:
              custom_colour_json,

            hero:
              normalise_jsonb(
                @business_website.hero
              ),

            hero_image:
              attachment_json(
                @business_website.hero_image
              ),

            services:
              normalise_jsonb(
                @business_website.services
              ),

            about_us:
              normalise_jsonb(
                @business_website.about_us
              ),

            about_image:
              attachment_json(
                @business_website.about_image
              ),

            visit:
              normalise_jsonb(
                @business_website.visit
              ),

            gallery:
              gallery_json,

            created_at:
              @business_website.created_at,

            updated_at:
              @business_website.updated_at
          }
        end

        # ==========================================
        # CUSTOM COLOUR JSON
        # ==========================================

        def custom_colour_json
          colour =
            @business_website
              .website_settings_colour

          return nil unless colour

          {
            hex_code:
              colour.hex_code,

            shades: {
              "950" => colour.colour_950,
              "900" => colour.colour_900,
              "800" => colour.colour_800,
              "700" => colour.colour_700,
              "600" => colour.colour_600,
              "500" => colour.colour_500,
              "400" => colour.colour_400,
              "300" => colour.colour_300,
              "200" => colour.colour_200,
              "100" => colour.colour_100,
              "50" => colour.colour_50
            }
          }
        end

        # ==========================================
        # ATTACHMENT JSON
        # ==========================================

        def attachment_json(attachment)
          return {
            attached: false,
            url: nil
          } unless attachment.attached?

          {
            attached: true,
            id: attachment.id,
            filename:
              attachment.filename.to_s,
            content_type:
              attachment.content_type,
            url:
              rails_blob_url(
                attachment,
                host: request.base_url
              )
          }
        end

        # ==========================================
        # GALLERY JSON
        # ==========================================

        def gallery_json
          @business_website
            .gallery_images
            .map do |image|

            {
              id: image.id,

              filename:
                image.filename.to_s,

              content_type:
                image.content_type,

              url:
                rails_blob_url(
                  image,
                  host: request.base_url
                )
            }
          end
        end

        # ==========================================
        # COLOUR OPTIONS
        # ==========================================

        def colour_options
          [
            {
              value: "blue",
              name: "Ocean Blue",
              description:
                "Professional and dependable"
            },
            {
              value: "indigo",
              name: "Modern Indigo",
              description:
                "Clean and contemporary"
            },
            {
              value: "violet",
              name: "Creative Violet",
              description:
                "Bold and distinctive"
            },
            {
              value: "purple",
              name: "Deep Purple",
              description:
                "Premium and confident"
            },
            {
              value: "pink",
              name: "Rose Pink",
              description:
                "Friendly and expressive"
            },
            {
              value: "rose",
              name: "Warm Rose",
              description:
                "Welcoming and personal"
            },
            {
              value: "red",
              name: "Strong Red",
              description:
                "Energetic and direct"
            },
            {
              value: "orange",
              name: "Bright Orange",
              description:
                "Warm and energetic"
            },
            {
              value: "amber",
              name: "Golden Amber",
              description:
                "Positive and approachable"
            },
            {
              value: "emerald",
              name: "Fresh Emerald",
              description:
                "Natural and trustworthy"
            },
            {
              value: "green",
              name: "Natural Green",
              description:
                "Calm and established"
            },
            {
              value: "teal",
              name: "Calm Teal",
              description:
                "Balanced and professional"
            },
            {
              value: "cyan",
              name: "Clear Cyan",
              description:
                "Fresh and modern"
            },
            {
              value: "slate",
              name: "Classic Slate",
              description:
                "Neutral and sophisticated"
            }
          ]
        end

        # ==========================================
        # ICON OPTIONS
        # ==========================================

        def icon_options
          [
            ["calendar-check", "Calendar"],
            ["calendar-days", "Appointments"],
            ["clock-3", "Opening times"],
            ["map-pin", "Location"],
            ["navigation", "Directions"],
            ["phone", "Phone"],
            ["mail", "Email"],
            ["badge-check", "Trusted"],
            ["circle-check-big", "Confirmed"],
            ["star", "Quality"],
            ["heart", "Care"],
            ["sparkles", "Premium"],
            ["shield-check", "Secure"],
            ["circle-pound-sterling", "Pricing"],
            ["wallet-cards", "Payment"],
            ["users", "Customers"],
            ["user-round-check", "Professional"],
            ["briefcase-business", "Business"],
            ["house", "Home"],
            ["building-2", "Premises"],
            ["scissors", "Barbering"],
            ["wrench", "Repairs"],
            ["hammer", "Trades"],
            ["camera", "Photography"],
            ["dumbbell", "Fitness"],
            ["graduation-cap", "Training"],
            ["car", "Transport"],
            ["truck", "Delivery"],
            ["message-circle", "Consultation"],
            ["thumbs-up", "Recommended"]
          ].map do |value, label|
            {
              value: value,
              label: label
            }
          end
        end

        # ==========================================
        # JSONB
        # ==========================================

        def normalise_jsonb(value)
          return value unless value.is_a?(String)

          JSON.parse(value)

        rescue JSON::ParserError
          begin
            JSON.parse(
              value.gsub("=>", ":")
            )
          rescue JSON::ParserError
            value
          end
        end
      end
    end
  end
end