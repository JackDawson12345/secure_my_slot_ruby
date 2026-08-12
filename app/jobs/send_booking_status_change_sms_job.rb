class SendBookingStatusChangeSmsJob < ApplicationJob
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
    status = booking.status.to_s.humanize.downcase

    if booking.status.to_s.downcase == "cancelled"
      "Your booking with #{booking.business.business_name} has been cancelled. " \
        "#{booking.service.name} on #{date} at #{time}. " \
        "If you would like to make another booking, please book again."

    elsif booking.status.to_s.downcase == "completed"
      "Your booking with #{booking.business.business_name} has been completed. " \
        "Thank you for your booking. We hope you enjoyed your #{booking.service.name}."

    else
      "Your booking with #{booking.business.business_name} has been updated to #{status}. " \
        "#{booking.service.name} on #{date} at #{time}."
    end
  end
end
