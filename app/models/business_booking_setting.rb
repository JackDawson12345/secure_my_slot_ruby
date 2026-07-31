class BusinessBookingSetting < ApplicationRecord
  BOOKING_INTERVALS = [15, 30, 45, 60].freeze
  MINIMUM_NOTICE_OPTIONS = [60, 120, 240, 720, 1_440].freeze
  ADVANCE_BOOKING_OPTIONS = [14, 30, 60, 90].freeze
  BUFFER_OPTIONS = [0, 5, 10, 15, 30].freeze

  belongs_to :business, inverse_of: :booking_setting

  validates :business_id, uniqueness: true

  validates :booking_interval_minutes,
            inclusion: { in: BOOKING_INTERVALS }

  validates :minimum_notice_minutes,
            inclusion: { in: MINIMUM_NOTICE_OPTIONS }

  validates :advance_booking_days,
            inclusion: { in: ADVANCE_BOOKING_OPTIONS }

  validates :buffer_minutes,
            inclusion: { in: BUFFER_OPTIONS }
end