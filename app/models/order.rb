class Order < ApplicationRecord

  before_create :generate_public_id

  belongs_to :business
  belongs_to :user

  has_many :order_items,
           dependent: :destroy

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    completed: "completed",
    cancelled: "cancelled"
  }

  enum :payment_method, {
    cash: "cash",
    stripe: "stripe"
  }

  enum :payment_status, {
    unpaid: "unpaid",
    paid: "paid"
  }

  private


  def generate_public_id

    self.public_id ||= SecureRandom.uuid

  end

end