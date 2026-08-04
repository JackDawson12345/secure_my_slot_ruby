class BusinessWebsite < ApplicationRecord
  COLOUR_SCHEMES = %w[
    blue
    indigo
    violet
    purple
    pink
    rose
    red
    orange
    amber
    emerald
    green
    teal
    cyan
    slate
  ].freeze

  belongs_to :business

  has_one_attached :hero_image
  has_one_attached :about_image

  validates :business_id, uniqueness: true

  validates :colour,
            presence: true,
            inclusion: { in: COLOUR_SCHEMES }

  before_validation :ensure_json_structure

  private

  def ensure_json_structure
    self.colour = "blue" if colour.blank?

    self.hero ||= {}
    self.services ||= {}
    self.about_us ||= {}
    self.visit ||= {}

    hero["title"] ||= ""
    hero["sentence"] ||= ""
    hero["info_boxes"] ||= default_hero_info_boxes

    services["title"] ||= ""
    services["sentence"] ||= ""

    about_us["title"] ||= ""
    about_us["paragraph"] ||= ""
    about_us["icon_boxes"] ||= default_about_icon_boxes

    visit["title"] ||= ""
    visit["sentence"] ||= ""
  end

  def default_hero_info_boxes
    Array.new(3) do
      {
        "icon" => "",
        "title" => ""
      }
    end
  end

  def default_about_icon_boxes
    Array.new(4) do
      {
        "title" => "",
        "sentence" => ""
      }
    end
  end
end