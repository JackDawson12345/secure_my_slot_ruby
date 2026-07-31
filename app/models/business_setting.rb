class BusinessSetting < ApplicationRecord
  belongs_to :business

  before_save :clear_coordinates_if_address_changed

  private

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
