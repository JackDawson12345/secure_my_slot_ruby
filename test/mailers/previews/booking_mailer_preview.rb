# Preview all emails at http://localhost:3000/rails/mailers/booking_mailer
class BookingMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/booking_mailer/appointment_reminder
  def appointment_reminder
    BookingMailer.appointment_reminder
  end
end
