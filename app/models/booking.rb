class Booking < ApplicationRecord
  belongs_to :business
  belongs_to :user
  belongs_to :service

  validate :time_available


  def time_available

    overlapping = business.bookings
                          .where(date: date)
                          .where.not(id: id)
                          .where.not(status: "cancelled")
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
end
