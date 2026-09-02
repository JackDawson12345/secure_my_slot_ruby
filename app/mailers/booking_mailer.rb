class BookingMailer < ApplicationMailer
  def appointment_reminder
    set_booking_details
    set_consultation_details

    mail(
      to: @user.email,
      subject: "Reminder: your appointment is in one hour"
    )
  end

  def customer_booking_confirmation
    set_booking_details
    set_consultation_details

    mail(
      to: @user.email,
      subject: "Booking confirmed with #{@business.business_name}"
    )
  end

  def business_booking_notification
    set_booking_details

    mail(
      to: @business.user.email,
      subject: "New booking received - #{@service.name}"
    )
  end

  def booking_cancelled
    set_booking_details

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
    set_booking_details
    set_consultation_details

    mail(
      to: @user.email,
      subject: "Booking updated - #{@booking.status.to_s.humanize}"
    )
  end

  private

  def set_booking_details
    @booking = params[:booking]
    @business = @booking.business
    @service = @booking.service
    @user = @booking.user

    service_price = @service.price || 0
    amount_paid = @booking.amount_paid || 0

    @remaining_balance = [
      service_price - amount_paid,
      0
    ].max
  end

  def set_consultation_details
    @consultation_required =
      @business.consultation_form.present? &&
      @booking.consultation_token.present? &&
      @booking.consultation_responses.blank?

    return unless @consultation_required

    @consultation_form_url =
      business_site_consultation_form_url(
        token: @booking.consultation_token,
        subdomain: @business.page_address
      )
  end
end