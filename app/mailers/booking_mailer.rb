# app/mailers/booking_mailer.rb

class BookingMailer < ApplicationMailer
  def appointment_reminder
    @booking = params[:booking]
    @business = @booking.business
    @service = @booking.service
    @user = @booking.user

    service_price = @service.price || 0
    amount_paid = @booking.amount_paid || 0

    @remaining_balance = [service_price - amount_paid, 0].max

    mail(
      to: @user.email,
      subject: "Reminder: your appointment is in one hour"
    )
  end
end