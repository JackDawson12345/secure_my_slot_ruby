class SocialPostTemplate < ApplicationRecord
  has_one_attached :preview_image

  has_many :social_posts, dependent: :restrict_with_error
end
