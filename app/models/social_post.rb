class SocialPost < ApplicationRecord
  belongs_to :business
  belongs_to :social_post_template

  has_one_attached :image
  has_one_attached :logo
  has_one_attached :generated_image
end
