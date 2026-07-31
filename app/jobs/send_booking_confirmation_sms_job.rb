class SendBookingConfirmationSmsJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.includes(:business, :service, :user).find_by(id: booking_id)

    return unless booking
    return if booking.user.phone_number.blank?

    SmsService.send_message(
      to: booking.user.phone_number,
      body: message_for(booking)
    )
  end

  private

  def message_for(booking)
    date = booking.date.strftime("%-d %B %Y")
    time = booking.time.strftime("%-I:%M %p")

    "Your booking with #{booking.business.business_name} has been received. " \
      "#{booking.service.name} on #{date} at #{time}."
  end
end