class Booking < ApplicationRecord

  before_create :set_consultation_token

  belongs_to :business
  belongs_to :user
  belongs_to :service

  belongs_to :agent,
             class_name: "User",
             optional: true

  has_many_attached :images

  validate :maximum_images

  validate :time_available

  enum :payment_status, {
    not_required: "not_required",
    awaiting_payment: "awaiting_payment",
    paid: "paid",
    payment_failed: "payment_failed",
    refunded: "refunded"
  }, prefix: true


  def time_available

    overlapping = business.bookings
                          .where(date: date)
                          .where.not(id: id)
                          .where.not(status: ["cancelled", "no_show"])
                          .any? do |booking|

      booking_start = booking.time
      booking_end =
        booking.time +
        booking.service.minutes_duration.minutes


      new_start = time
      new_end =
        time +
        service.minutes_duration.minutes


      new_start < booking_end &&
        new_end > booking_start

    end


    errors.add(:time, "is already booked") if overlapping

  end

  private

  def set_consultation_token
    self.consultation_token ||= SecureRandom.uuid
  end

  def maximum_images
    if images.attachments.size > 10
      errors.add(:images, "You can upload a maximum of 10 images")
    end
  end
end
