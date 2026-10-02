class BusinessAgent < ApplicationRecord
  belongs_to :business
  belongs_to :user

  has_many :service_agents, dependent: :destroy
  has_many :services, through: :service_agents

  validates :user_id, uniqueness: { scope: :business_id }

  enum :status, {
    invited: "invited",
    active: "active",
    inactive: "inactive"
  }
end