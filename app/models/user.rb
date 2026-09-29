class User < ApplicationRecord
  attr_accessor :invitation_creation

  enum :role, {
    admin: 0,
    business: 1,
    customer: 2,
    agent: 3
  }

  has_many :business_agents, dependent: :destroy

  has_many :agent_businesses,
           through: :business_agents,
           source: :business

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  has_one :business, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_one :customer_setting, dependent: :destroy
  has_many :orders, dependent: :destroy

  has_many :business_customers, dependent: :destroy

  has_many :businesses,
           through: :business_customers

  validates :terms_accepted,
            acceptance: {
              accept: true,
              message: "must be accepted"
            },
            on: :create,
            unless: :invitation_creation

  validate :password_complexity,
           if: :password_required?,
           unless: :invitation_creation

  before_create :record_terms_acceptance

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  private

  def password_required?
    password.present? || password_confirmation.present?
  end

  def password_complexity
    rules = {
      "must contain at least 8 characters" => password.length >= 8,
      "must contain at least one uppercase letter" => password.match?(/[A-Z]/),
      "must contain at least one number" => password.match?(/[0-9]/),
      "must contain at least one special character" => password.match?(/[^A-Za-z0-9]/)
    }

    rules.each do |message, valid|
      errors.add(:password, message) unless valid
    end
  end

  def record_terms_acceptance
    self.terms_accepted_at = Time.current if terms_accepted?
  end
end