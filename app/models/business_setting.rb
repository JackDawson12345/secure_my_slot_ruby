class BusinessSetting < ApplicationRecord
  belongs_to :business

  before_save :clear_coordinates_if_address_changed

  has_one_attached :logo

  validate :acceptable_logo

  private

  def acceptable_logo
    return unless logo.attached?

    allowed_types = [
      "image/png",
      "image/jpeg",
      "image/webp"
    ]

    unless allowed_types.include?(logo.blob.content_type)
      errors.add(:logo, "must be a PNG, JPG or WebP image")
    end

    if logo.blob.byte_size > 5.megabytes
      errors.add(:logo, "must be smaller than 5 MB")
    end
  end

  def clear_coordinates_if_address_changed
    address_changed = [
      :address_line_1,
      :address_line_2,
      :town_or_city,
      :postcode,
      :country
    ].any? do |attribute|
      will_save_change_to_attribute?(attribute)
    end

    return unless address_changed

    self.latitude = nil
    self.longitude = nil
  end
end
