class BusinessPortal::WebsiteColourSettingsController <
  BusinessPortal::BaseController

  before_action :set_business
  before_action :set_business_website


  def update
    unless current_user.business.feature_enabled?(:website_colour)
      redirect_to business_website_settings_path,
                  alert: "Upgrade to Pro to customise your website colours."
      return
    end

    settings = website_colour_params

    if settings["colour"] == "custom"
      save_custom_colour(settings["custom_colour"])
    else
      @business_website.website_settings_colour&.destroy
    end

    settings.delete("custom_colour")

    if @business_website.update(settings)
      redirect_to business_website_settings_path,
                  notice: "Website colours updated successfully."
    else
      flash.now[:alert] = "Please correct the errors below."
      render "business_portal/website_settings/index",
             status: :unprocessable_entity
    end
  end


  def generate_colours
    colour = JSON.parse(request.body.read)["colour"]

    render json: ColourPaletteGenerator.new(colour).generate
  end


  private


  def website_colour_params
    params
      .require(:business_website)
      .permit(
        :colour,
        :custom_colour
      )
      .to_h
  end


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
    @business_website = @business.business_website
  end

end