class BusinessPortal::WebsiteSettingsController <
  BusinessPortal::BaseController

  before_action :set_business
  before_action :set_business_website

  def index
  end

  def update
    settings = website_settings_params

    if settings["colour"] == "custom"
      save_custom_colour(settings["custom_colour"])
    else
      @business_website.website_settings_colour&.destroy
    end

    settings.delete("custom_colour")

    if @business_website.update(settings)
      redirect_to business_website_settings_path,
                  notice: "Website settings updated successfully."
    else
      flash.now[:alert] = "Please correct the errors below."
      render :index, status: :unprocessable_entity
    end
  end

  def generate_colours
    colour = JSON.parse(request.body.read)["colour"]

    render json: ColourPaletteGenerator.new(colour).generate
  end

  private

  def save_custom_colour(hex_code)
    return if hex_code.blank?

    generated_colours = ColourPaletteGenerator
                          .new(hex_code)
                          .generate

    colour_settings = WebsiteSettingsColour.find_or_initialize_by(
      business_website: @business_website
    )

    colour_settings.update!(
      business: @business,
      hex_code: hex_code,
      colour_950: generated_colours["950"],
      colour_900: generated_colours["900"],
      colour_800: generated_colours["800"],
      colour_700: generated_colours["700"],
      colour_600: generated_colours["600"],
      colour_500: generated_colours["500"],
      colour_400: generated_colours["400"],
      colour_300: generated_colours["300"],
      colour_200: generated_colours["200"],
      colour_100: generated_colours["100"],
      colour_50: generated_colours["50"]
    )
  end

  def set_business
    @business = current_user.business
  end

  def set_business_website
    @business_website =
      @business.business_website ||
      @business.build_business_website(default_website_content)
  end

  def website_settings_params
    permitted = params
                  .require(:business_website)
                  .permit(
                    :colour,
                    :custom_colour,
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

    normalise_nested_boxes!(permitted)

    permitted
  end

  def normalise_nested_boxes!(permitted)
    hero_boxes = permitted.dig("hero", "info_boxes")

    if hero_boxes.is_a?(Hash)
      permitted["hero"]["info_boxes"] =
        hero_boxes
          .sort_by { |index, _values| index.to_i }
          .map(&:last)
    end

    about_boxes = permitted.dig("about_us", "icon_boxes")

    if about_boxes.is_a?(Hash)
      permitted["about_us"]["icon_boxes"] =
        about_boxes
          .sort_by { |index, _values| index.to_i }
          .map(&:last)
    end
  end

  def default_website_content
    {
      hero: {
        title: "",
        sentence: "",
        info_boxes: Array.new(3) do
          {
            icon: "",
            title: ""
          }
        end
      },
      services: {
        title: "",
        sentence: ""
      },
      about_us: {
        title: "",
        paragraph: "",
        icon_boxes: Array.new(4) do
          {
            title: "",
            sentence: ""
          }
        end
      },
      visit: {
        title: "",
        sentence: ""
      }
    }
  end
end