# app/mailers/booking_mailer.rb

class BookingMailer < ApplicationMailer
  def appointment_reminder
    @booking = params[:booking]
    @business = @booking.business
    @service = @booking.service
    @user = @booking.user

    mail(
      to: @user.email,
      subject: "Reminder: your appointment is in one hour"
    )
  end
end