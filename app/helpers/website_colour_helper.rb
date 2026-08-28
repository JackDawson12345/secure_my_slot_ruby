module WebsiteColourHelper

  def custom_colour?
    @business.business_website.colour == "custom"
  end


  def website_colour_class(type, shade, opacity = nil)
    if custom_colour?
      colour = @business.business_website.website_settings_colour
                 &.public_send("colour_#{shade}")

      return unless colour

      if opacity
        rgba = hex_to_rgba(colour, opacity / 100.0)
        return "#{type}-[#{rgba}]"
      end

      return "#{type}-[#{colour}]"
    end

    colour_class = "#{type}-#{@business.business_website.colour}-#{shade}"

    opacity ? "#{colour_class}/#{opacity}" : colour_class
  end


  private

  def hex_to_rgba(hex, opacity = 1)
    hex = hex.delete("#")

    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)

    "rgba(#{r}, #{g}, #{b}, #{opacity})"
  end

end