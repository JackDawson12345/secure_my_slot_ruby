class PageView < ApplicationRecord
  belongs_to :pageable, polymorphic: true

  before_validation :set_device_type, on: :create
  before_validation :set_traffic_source, on: :create

  private

  def set_device_type
    agent = user_agent.to_s.downcase

    self.device_type =
      if agent.match?(/ipad|tablet|kindle|silk/)
        "tablet"
      elsif agent.match?(/mobile|iphone|ipod|android/)
        "mobile"
      else
        "desktop"
      end
  end

  def set_traffic_source
    return self.traffic_source = "direct" if referrer.blank?

    source = referrer.to_s.downcase

    self.traffic_source =
      if source.match?(/google\.|bing\.com|search\.yahoo\.com|duckduckgo\.com/)
        "organic_search"
      elsif source.match?(/facebook\.com|instagram\.com|linkedin\.com|tiktok\.com|twitter\.com|x\.com|t\.co/)
        "social"
      else
        "other"
      end
  end
end