class PushToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :platform,
            presence: true,
            inclusion: { in: %w[ios android] }

  scope :for_platform, ->(platform) {
    where(platform: platform)
  }
end