class BusinessSitesController < ApplicationController

  before_action :set_business
  layout "business_site"

  def show
    @coordinates = geocode_business_address
  end


  private

  def set_business
    @business = Business.find_by(page_address: request.subdomain)

    render file: Rails.root.join("public/404.html"), status: :not_found unless @business
  end

  def geocode_business_address
    address = [
      @business.business_setting.address_line_1,
      @business.business_setting.address_line_2,
      @business.business_setting.town_or_city,
      @business.business_setting.postcode,
      @business.business_setting.country
    ].compact.join(", ")

    response = HTTParty.get(
      "https://maps.googleapis.com/maps/api/geocode/json",
      query: {
        address: address,
        key: "AIzaSyBeTSw6kn3eIqQab4tZy1-EXF9gM91R97U"
      }
    )

    result = response.parsed_response["results"].first

    return nil unless result

    {
      latitude: result["geometry"]["location"]["lat"],
      longitude: result["geometry"]["location"]["lng"]
    }
  end

end