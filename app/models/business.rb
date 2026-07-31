class Business < ApplicationRecord
  belongs_to :user

  store_accessor :address,
                 :line_1,
                 :line_2,
                 :city,
                 :postcode,
                 :country

  validates :business_name, presence: true

  validates :page_address,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: {
              with: /\A[a-z0-9-]+\z/,
              message: "can only contain lowercase letters, numbers and hyphens"
            }

  before_validation :normalise_page_address

  has_many :opening_hours,
           -> { order(:day_of_week) },
           class_name: "BusinessOpeningHour",
           dependent: :destroy,
           inverse_of: :business

  has_one :booking_setting,
          class_name: "BusinessBookingSetting",
          dependent: :destroy,
          inverse_of: :business

  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy

  has_one :business_setting,
          dependent: :destroy,
          inverse_of: :business

  accepts_nested_attributes_for :opening_hours
  accepts_nested_attributes_for :booking_setting

  after_create :create_default_availability

  def open_today?
    opening_hour = opening_hours.find_by(
      day_of_week: current_day_of_week
    )

    opening_hour&.open? || false
  end

  def open_now?
    opening_hour = opening_hours.find_by(
      day_of_week: current_day_of_week
    )

    return false unless opening_hour&.open?
    return false if opening_hour.opens_at.blank?
    return false if opening_hour.closes_at.blank?

    current_time = Time.current.seconds_since_midnight
    opening_time = opening_hour.opens_at.seconds_since_midnight
    closing_time = opening_hour.closes_at.seconds_since_midnight

    current_time.between?(opening_time, closing_time)
  end

  def distance_to_customer(customer)
    business_coordinates = coordinates_for_setting(
      setting: business_setting,
      address: business_full_address
    )

    customer_coordinates = coordinates_for_setting(
      setting: customer.customer_setting,
      address: customer_full_address(customer)
    )

    return nil unless business_coordinates && customer_coordinates

    DistanceCalculator.miles_between(
      latitude_one: business_coordinates[:latitude],
      longitude_one: business_coordinates[:longitude],
      latitude_two: customer_coordinates[:latitude],
      longitude_two: customer_coordinates[:longitude]
    ).round(2)
  end

  def stripe_connected?
    stripe_account_id.present?
  end

  def stripe_ready?
    stripe_connected? &&
      stripe_details_submitted? &&
      stripe_charges_enabled? &&
      stripe_payouts_enabled?
  end

  private

  def current_day_of_week
    Date.current.wday - 1
  end

  def business_full_address
    [
      business_setting&.address_line_1,
      business_setting&.address_line_2,
      business_setting&.town_or_city,
      business_setting&.postcode,
      business_setting&.country
    ].compact_blank.join(", ")
  end

  def customer_full_address(customer)
    customer_setting = customer.customer_setting

    [
      customer_setting&.address_line_1,
      customer_setting&.address_line_2,
      customer_setting&.town_or_city,
      customer_setting&.postcode,
      customer_setting&.country
    ].compact_blank.join(", ")
  end

  def coordinates_for_setting(setting:, address:)
    return nil if setting.nil?
    return nil if address.blank?

    if setting.latitude.present? && setting.longitude.present?
      return {
        latitude: setting.latitude.to_f,
        longitude: setting.longitude.to_f
      }
    end

    coordinates = geocode_address(address)

    return nil unless coordinates

    setting.update!(
      latitude: coordinates[:latitude],
      longitude: coordinates[:longitude]
    )

    coordinates
  end

  def geocode_address(address)
    response = HTTParty.get(
      "https://maps.googleapis.com/maps/api/geocode/json",
      query: {
        address: address,
        key: google_maps_api_key
      },
      timeout: 10
    )

    unless response.success?
      Rails.logger.error(
        "Google geocoding request failed with HTTP status #{response.code}"
      )

      return nil
    end

    parsed_response = response.parsed_response

    unless parsed_response["status"] == "OK"
      Rails.logger.error(
        "Google geocoding failed for #{address.inspect}: " \
          "#{parsed_response['status']} " \
          "#{parsed_response['error_message']}"
      )

      return nil
    end

    location = parsed_response.dig(
      "results",
      0,
      "geometry",
      "location"
    )

    return nil unless location

    {
      latitude: location["lat"].to_f,
      longitude: location["lng"].to_f
    }
  rescue HTTParty::Error,
    SocketError,
    Timeout::Error,
    Errno::ECONNREFUSED => error
    Rails.logger.error(
      "Google geocoding request failed for #{address.inspect}: " \
        "#{error.class} #{error.message}"
    )

    nil
  end

  def google_maps_api_key
    Rails.application.credentials.dig(:google_maps, :api_key)
  end

  def normalise_page_address
    self.page_address = page_address.to_s
                                    .strip
                                    .downcase
                                    .gsub(/\s+/, "-")
                                    .gsub(/[^a-z0-9-]/, "")
  end

  def create_default_availability
    BusinessOpeningHour.day_of_weeks.each_key do |day|
      weekday = !%w[saturday sunday].include?(day)

      opening_hours.create!(
        day_of_week: day,
        open: weekday,
        opens_at: weekday ? "09:00" : nil,
        closes_at: weekday ? "17:30" : nil
      )
    end

    create_booking_setting!(
      booking_interval_minutes: 30,
      minimum_notice_minutes: 240,
      advance_booking_days: 30,
      buffer_minutes: 0
    )
  end
end