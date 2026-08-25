class BookingHold < ApplicationRecord
  belongs_to :business
  belongs_to :service
  belongs_to :user

  belongs_to :booking,
             optional: true

  validates :date, presence: true
  validates :time, presence: true
  validates :expires_at, presence: true

  scope :active, -> {
    where(booking_id: nil)
      .where("expires_at > ?", Time.current)
  }

  scope :expired, -> {
    where(booking_id: nil)
      .where("expires_at <= ?", Time.current)
  }

  def active?
    booking_id.nil? && expires_at.future?
  end

  def completed?
    booking_id.present?
  end
end