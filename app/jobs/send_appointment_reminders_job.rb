# app/jobs/send_appointment_reminders_job.rb

class SendAppointmentRemindersJob < ApplicationJob
  queue_as :default

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
    [
      Time.zone.today,
      Time.zone.tomorrow
    ]
  end

  def reminder_due?(booking)
    appointment_time = appointment_time_for(booking)

    appointment_time.between?(
      55.minutes.from_now,
      65.minutes.from_now
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

  def send_reminders(booking)
    booking.with_lock do
      booking.reload

      send_email_reminder(booking)
      send_sms_reminder(booking)
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

    "Reminder: your #{service_name} appointment with " \
      "#{business_name} starts at #{appointment_time}, in approximately one hour."
  end
end