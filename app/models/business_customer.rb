class BusinessCustomer < ApplicationRecord
  belongs_to :business
  belongs_to :user

  validates :user_id, uniqueness: { scope: :business_id }
end
