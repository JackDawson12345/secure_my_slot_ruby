class PaymentLinksMailer < ApplicationMailer

  def send_customer_payment_link(booking, payment_link, payment_amount)
    @booking = booking
    @user = booking.user
    @business = booking.business
    @payment_link = payment_link
    @payment_amount = payment_amount

    mail(
      to: @user.email,
      subject: "Payment request from #{@business.business_name}"
    )
  end


  def customer_payment_link_received(booking, payment_amount)
    @booking = booking
    @user = booking.user
    @business = booking.business
    @payment_amount = payment_amount

    mail(
      to: @user.email,
      subject: "Payment received for your booking"
    )
  end

  def business_payment_link_received(booking, payment_amount)
    @booking = booking
    @user = booking.user
    @business = booking.business
    @payment_amount = payment_amount

    mail(
      to: @business.user.email,
      subject: "Payment received from #{@user.first_name} #{@user.last_name}"
    )
  end

end