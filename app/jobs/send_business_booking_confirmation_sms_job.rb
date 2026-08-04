class SendBusinessBookingConfirmationSmsJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking
                .includes(:business, :service, :user)
                .find_by(id: booking_id)

    return unless booking
    return if booking.business.phone_number.blank?

    SmsService.send_message(
      to: booking.business.phone_number,
      body: message_for(booking)
    )
  end

  private

  def message_for(booking)
    date = booking.date.strftime("%-d %B %Y")
    time = booking.time.strftime("%-I:%M %p")
    customer_name = [
                      booking.user&.first_name,
                      booking.user&.last_name
                    ].compact_blank.join(" ").presence || booking.user&.email || "A customer"

    "New booking received from #{customer_name}. " \
      "#{booking.service.name} on #{date} at #{time}."
  end
end