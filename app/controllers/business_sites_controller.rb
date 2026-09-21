class BusinessSitesController < ApplicationController

  before_action :set_business

  layout "business_site"

  def show
    track_page_view(@business)

    @coordinates = geocode_business_address


    settings = @business.business_setting
    check_verify_link = settings.check_verify_link

    if check_verify_link.present?
      check_verify_slug = URI.parse(check_verify_link).path.split("/").last

      uri = URI("https://www.checkverify.co.uk/api/v1/reviews/user/#{check_verify_slug}")

      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)

        recent_reviews = data["reviews"]
                           .sort_by { |review| Time.parse(review["created_at"]) }
                           .reverse
                           .first(10)

        @total_reviews =  data.dig("user", "total_reviews")
        @average_rating = data.dig("user", "average_rating").to_f.round(2)
        @reviews = recent_reviews
      end
    end

  end

  def check_service_coupon

    coupon = @business.service_coupons.find do |service_coupon|
      service_coupon.code.strip.casecmp(params[:code].strip).zero?
    end

    unless coupon
      render json: {
        success: false,
        message: "Coupon code not found."
      }
      return
    end


    unless coupon.active?
      render json: {
        success: false,
        message: "This coupon is no longer active."
      }
      return
    end


    if coupon.expires_at.present? && coupon.expires_at < Time.current
      render json: {
        success: false,
        message: "This coupon has expired."
      }
      return
    end


    service_id = params[:service_id].to_s


    if coupon.services.present?

      allowed_services =
        coupon.services.map(&:to_s)

      unless allowed_services.include?(service_id)
        render json: {
          success: false,
          message: "This coupon cannot be used for this service."
        }
        return
      end

    end


    service = @business.services.find(service_id)


    original_price = service.price.to_d


    discounted_price =
      case coupon.coupon_type

      when "percentage"
        original_price -
          (original_price * (coupon.discount / 100))

      when "fixed"
        original_price - coupon.discount

      else
        original_price
      end


    discounted_price = 0 if discounted_price < 0


    render json: {
      success: true,
      message: "Coupon applied successfully.",
      original_price: original_price.to_f,
      price: discounted_price.round(2).to_f
    }

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

  def agreement_form
    @agreement_status = AgreementStatus.find_by(token: params[:token])

    return redirect_to root_path unless @agreement_status

    @agreement = @agreement_status.agreement
  end

  def submit_agreement_form

    @agreement_status = AgreementStatus.find_by(token: params[:token])

    if params[:signature_data].present?

      params[:signature_data].each do |name, signature|

        next if signature.blank?

        image_data = signature.split(",").last

        @agreement_status.signatures.attach(
          io: StringIO.new(Base64.decode64(image_data)),
          filename: "#{name}.png",
          content_type: "image/png"
        )

      end

    end


    browser = Browser.new(request.user_agent)

    @agreement_status.update!(
      status: "signed",
      signed_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      device: "#{browser.device.name} - #{browser.name} #{browser.version}"
    )


    redirect_to business_site_agreement_form_path(token: @agreement_status.token),
                notice: "Agreement signed successfully."

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