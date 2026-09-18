class ServiceCoupon < ApplicationRecord
  belongs_to :business

  validates :name, :code, :coupon_type, presence: true
end
