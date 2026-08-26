# app/jobs/send_appointment_reminders_job.rb

class SendAppointmentRemindersJob < ApplicationJob
  queue_as :default

  REMINDER_TIMINGS = {
    "1 hour before" => 1.hour,
    "2 hours before" => 2.hours,
    "24 hours before" => 24.hours,
    "48 hours before" => 48.hours
  }.freeze

  DEFAULT_REMINDER_TIMING = "1 hour before"
  DEFAULT_REMINDER_METHOD = "Email only"

  def perform
    Booking
      .includes(:user, :business, :service)
      .where.not(status: "cancelled")
      .where(date: relevant_dates)
      .where(
        "reminder_email_sent_at IS NULL OR reminder_sms_sent_at IS NULL"
      )
      .find_each do |booking|

      next unless reminder_due?(booking)

      send_reminders(booking)
    end
  end

  private

  def relevant_dates
    Time.zone.today..2.days.from_now.to_date
  end

  def reminder_due?(booking)
    appointment_time = appointment_time_for(booking)
    reminder_time = appointment_time - reminder_duration_for(booking)

    reminder_time.between?(
      5.minutes.ago,
      5.minutes.from_now
    )
  end

  def appointment_time_for(booking)
    Time.zone.local(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      booking.time.hour,
      booking.time.min
    )
  end

  def reminder_duration_for(booking)
    REMINDER_TIMINGS.fetch(
      reminder_timing_for(booking),
      1.hour
    )
  end

  def reminder_timing_for(booking)
    booking.user.customer_settings&.reminder_timing.presence ||
      DEFAULT_REMINDER_TIMING
  end

  def reminder_method_for(booking)
    booking.user.customer_settings&.reminder_method.presence ||
      DEFAULT_REMINDER_METHOD
  end

  def send_reminders(booking)
    booking.with_lock do
      booking.reload

      case reminder_method_for(booking)
      when "Email and SMS"
        send_email_reminder(booking)
        send_sms_reminder(booking)

      when "SMS only"
        send_sms_reminder(booking)

      else
        # Also acts as the fallback for nil/invalid values
        send_email_reminder(booking)
      end
    end
  end

  def send_email_reminder(booking)
    return if booking.reminder_email_sent_at.present?
    return if booking.user.email.blank?

    BookingMailer
      .with(booking: booking)
      .appointment_reminder
      .deliver_now

    booking.update!(
      reminder_email_sent_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error(
      "Appointment reminder email failed for booking #{booking.id}: " \
        "#{e.class} - #{e.message}"
    )
  end

  def send_sms_reminder(booking)
    return if booking.reminder_sms_sent_at.present?
    return if booking.user.phone_number.blank?

    SmsService.send_message(
      to: booking.user.phone_number,
      body: sms_message(booking)
    )

    booking.update!(
      reminder_sms_sent_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error(
      "Appointment reminder SMS failed for booking #{booking.id}: " \
        "#{e.class} - #{e.message}"
    )
  end

  def sms_message(booking)
    business_name = booking.business.business_name
    service_name = booking.service.name
    appointment_time = booking.time.strftime("%-I:%M %p")

    message =
      "Reminder: your #{service_name} appointment with " \
        "#{business_name} is at #{appointment_time}."

    remaining_balance = remaining_balance_for(booking)

    if remaining_balance.positive?
      message +=
        " The remaining balance for your appointment is " \
          "#{format_currency(remaining_balance)}."
    end

    message
  end

  def remaining_balance_for(booking)
    service_price = booking.service.price || 0
    amount_paid = booking.amount_paid || 0

    [service_price - amount_paid, 0].max
  end

  def format_currency(amount)
    "£#{format('%.2f', amount)}"
  end
end