class BusinessAgentSetting < ApplicationRecord
  belongs_to :business

  enum :agent_selection, {
    allow_any: 0,
    require_selection: 1
  }

  enum :booking_visibility, {
    assigned_only: 0,
    all_bookings: 1
  }

  validates :business_id, uniqueness: true
end