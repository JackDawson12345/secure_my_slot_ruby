class User < ApplicationRecord
  enum :role, {
    admin: 0,
    business: 1,
    customer: 2
  }

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

  validates :terms_accepted,
            acceptance: {
              accept: true,
              message: "must be accepted"
            },
            on: :create

  before_create :record_terms_acceptance

  private

  def record_terms_acceptance
    self.terms_accepted_at = Time.current if terms_accepted?
  end
end