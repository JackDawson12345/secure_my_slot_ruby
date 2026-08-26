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

  def customer_booking_confirmation
    @booking = params[:booking]
    @business = @booking.business
    @service = @booking.service
    @user = @booking.user

    service_price = @service.price || 0
    amount_paid = @booking.amount_paid || 0

    @remaining_balance = [service_price - amount_paid, 0].max

    mail(
      to: @user.email,
      subject: "Booking confirmed with #{@business.business_name}"
    )
  end

  def business_booking_notification
    @booking = params[:booking]
    @business = @booking.business
    @service = @booking.service
    @user = @booking.user

    service_price = @service.price || 0
    amount_paid = @booking.amount_paid || 0

    @remaining_balance = [service_price - amount_paid, 0].max

    mail(
      to: @business.user.email,
      subject: "New booking received - #{@service.name}"
    )
  end

  def booking_cancelled
    @booking = params[:booking]
    @business = @booking.business
    @service = @booking.service
    @user = @booking.user

    service_price = @service.price || 0
    amount_paid = @booking.amount_paid || 0

    @remaining_balance = [service_price - amount_paid, 0].max

    mail(
      to: @business.user.email,
      subject: "Booking cancelled - #{@service.name}"
    )
  end

  def daily_appointment_summary
    @business = params[:business]
    @bookings = params[:bookings]
    @date = params[:date]

    mail(
      to: @business.user.email,
      subject: "Your appointments for #{@date.strftime('%A %-d %B')}"
    )
  end

  def status_changed
    @booking = params[:booking]
    @business = @booking.business
    @service = @booking.service
    @user = @booking.user

    service_price = @service.price || 0
    amount_paid = @booking.amount_paid || 0

    @remaining_balance = [service_price - amount_paid, 0].max

    mail(
      to: @user.email,
      subject: "Booking updated - #{@booking.status.to_s.humanize}"
    )
  end
end