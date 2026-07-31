class Service < ApplicationRecord
  belongs_to :business

  STATUSES = %w[active inactive].freeze

  validates :name, presence: true
  validates :price,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :minutes_duration,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
end