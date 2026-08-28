class WebsiteSettingsColour < ApplicationRecord
  belongs_to :business
  belongs_to :business_website

  validates :hex_code, presence: true
end
