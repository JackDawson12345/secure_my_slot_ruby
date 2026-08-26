# app/jobs/send_daily_appointment_summaries_job.rb

class SendDailyAppointmentSummariesJob < ApplicationJob
  queue_as :default

  def perform
    today = Time.zone.today

    Business.find_each do |business|
      next unless business.business_setting&.daily_appointment_summary?

      bookings = business.bookings
                         .where(date: today)
                         .where.not(status: :cancelled)
                         .includes(:service, :user)
                         .order(:time)

      next if bookings.empty?

      BookingMailer.with(
        business: business,
        bookings: bookings,
        date: today
      ).daily_appointment_summary.deliver_now
    end
  end
end