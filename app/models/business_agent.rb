class BusinessAgent < ApplicationRecord
  belongs_to :business
  belongs_to :user

  validates :user_id, uniqueness: { scope: :business_id }

  enum :status, {
    invited: "invited",
    active: "active",
    inactive: "inactive"
  }
end
