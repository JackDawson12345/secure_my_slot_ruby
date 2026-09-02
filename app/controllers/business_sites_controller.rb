class BusinessSitesController < ApplicationController

  before_action :set_business

  layout "business_site"

  def show
    @coordinates = geocode_business_address
  end

  def consultation_form
    @consultation_form = @business.consultation_form

    unless params[:token].present?
      redirect_to root_url(
                    subdomain: @business.page_address
                  )
      return
    end

    @booking = @business.bookings.find_by(
      consultation_token: params[:token]
    )

    unless @booking
      redirect_to root_url(
                    subdomain: @business.page_address
                  )
      return
    end
  end

  def submit_consultation_form
    @consultation_form = @business.consultation_form

    @booking = @business.bookings.find_by(
      consultation_token: params[:token]
    )

    unless @booking
      redirect_to root_url(
                    subdomain: @business.page_address
                  )
      return
    end

    submitted_answers =
      params[:consultation]&.to_unsafe_h || {}

    responses = build_consultation_responses(
      @consultation_form.structure,
      submitted_answers
    )

    @booking.update!(
      consultation_responses: responses
    )

    redirect_to root_url(
                  subdomain: @business.page_address
                ),
                notice: "Consultation form submitted successfully."
  end

  private

  def set_business
    @business = Business.find_by(page_address: request.subdomain)

    render file: Rails.root.join("public/404.html"),
           status: :not_found unless @business
  end

  def consultation_form_params
    params.require(:consultation_form).permit(:structure)
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
        key: ENV["GOOGLE_MAPS_API_KEY"].presence ||
          Rails.application.credentials.dig(:google_maps, :api_key)
      }
    )

    result = response.parsed_response["results"].first

    return nil unless result

    {
      latitude: result["geometry"]["location"]["lat"],
      longitude: result["geometry"]["location"]["lng"]
    }
  end

  def build_consultation_responses(structure, submitted_answers)
    structure =
      if structure.is_a?(String)
        JSON.parse(structure) rescue []
      else
        structure || []
      end

    responses = []

    structure.each do |row|
      next unless row["type"] == "row"

      (row["children"] || []).each do |column|
        next unless column["type"] == "column"

        (column["children"] || []).each do |field|
          next unless %w[text number textarea select].include?(field["type"])

          field_name = field["name"]

          next if field_name.blank?
          next unless submitted_answers.key?(field_name)

          responses << {
            "id" => field["id"],
            "label" => field["placeholder"].presence || field_name.humanize,
            "value" => submitted_answers[field_name]
          }
        end
      end
    end

    responses
  end

end