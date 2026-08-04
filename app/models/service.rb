class Service < ApplicationRecord
  belongs_to :business

  after_initialize :set_default_icon, if: :new_record?

  ICONS = {
    "calendar-check" => "Appointment",
    "calendar-days" => "Calendar",
    "clock-3" => "Timed service",
    "message-circle" => "Consultation",
    "scissors" => "Hair and beauty",
    "sparkles" => "Beauty treatment",
    "heart" => "Care",
    "dumbbell" => "Fitness",
    "graduation-cap" => "Training",
    "camera" => "Photography",
    "wrench" => "Repairs",
    "hammer" => "Trades",
    "house" => "Home service",
    "building-2" => "Business premises",
    "car" => "Vehicle service",
    "truck" => "Delivery",
    "briefcase-business" => "Professional service",
    "shield-check" => "Protection",
    "circle-check-big" => "General service",
    "star" => "Premium service",
    "users" => "Group service",
    "user-round-check" => "One-to-one service",
    "paintbrush" => "Painting",
    "drill" => "Installation",
    "construction" => "Construction",
    "brick-wall" => "Building work",
    "ruler" => "Measurements",
    "shower-head" => "Bathroom service",
    "cooking-pot" => "Food service",
    "utensils" => "Dining",
    "coffee" => "Coffee service",
    "cake-slice" => "Celebrations",
    "flower-2" => "Flowers",
    "leaf" => "Gardening",
    "tree-pine" => "Outdoor service",
    "paw-print" => "Pet care",
    "baby" => "Childcare",
    "stethoscope" => "Health service",
    "activity" => "Wellbeing",
    "brain" => "Coaching",
    "hand-heart" => "Support",
    "notebook-pen" => "Administration",
    "calculator" => "Accounting",
    "scale" => "Legal service",
    "laptop" => "Technology",
    "wifi" => "Connectivity",
    "monitor-smartphone" => "Digital service",
    "printer" => "Printing",
    "music" => "Music",
    "mic-vocal" => "Entertainment",
    "party-popper" => "Events",
    "plane" => "Travel",
    "map" => "Tour",
    "package" => "Package",
    "shopping-bag" => "Retail",
    "shirt" => "Clothing",
    "gem" => "Jewellery",
    "key-round" => "Property",
    "bed-double" => "Accommodation",
    "bath" => "Spa treatment",
    "badge-pound-sterling" => "Paid service"
  }.freeze

  validates :icon,
            presence: true,
            inclusion: {
              in: ICONS.keys,
              message: "must be selected from the available icons"
            }

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

  validates :deposit,
            numericality: {
              greater_than: 0,
              allow_nil: true
            }

  validate :deposit_required_when_enabled
  validate :deposit_cannot_exceed_price

  before_validation :clear_deposit_when_disabled

  private

  def set_default_icon
    self.icon ||= "calendar-check"
  end

  def clear_deposit_when_disabled
    self.deposit = nil unless deposit_enabled?
  end

  def deposit_required_when_enabled
    return unless deposit_enabled?
    return if deposit.present?

    errors.add(:deposit, "must be entered when deposits are enabled")
  end

  def deposit_cannot_exceed_price
    return unless deposit_enabled?
    return if deposit.blank? || price.blank?
    return unless deposit > price

    errors.add(:deposit, "cannot be greater than the service price")
  end
end