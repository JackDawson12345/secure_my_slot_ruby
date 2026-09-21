class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    signature = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(
        payload,
        signature,
        ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue JSON::ParserError => e
      Rails.logger.error "Stripe webhook JSON error: #{e.message}"
      return head :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe webhook signature error: #{e.message}"
      return head :bad_request
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_session_completed(event.data.object)
    end

    head :ok
  end

  private

  def handle_checkout_session_completed(session)
    return unless session.payment_status == "paid"
    return unless session.metadata["payment_type"] == "payment_link"

    booking = Booking.find_by(
      payment_link_checkout_session_id: session.id
    )

    unless booking
      Rails.logger.error(
        "No booking found for payment link session #{session.id}"
      )
      return
    end

    # Prevent the same payment being processed twice
    if booking.payment_link_payment_intent_id == session.payment_intent
      Rails.logger.info(
        "Payment #{session.payment_intent} already processed"
      )
      return
    end

    payment_amount = session.amount_total.to_d / 100

    new_amount_paid =
      booking.amount_paid.to_d + payment_amount

    payment_status =
      if new_amount_paid >= booking.amount.to_d
        "paid"
      else
        "awaiting_payment"
      end

    booking.update!(
      amount_paid: new_amount_paid,
      payment_status: payment_status,
      payment_link_payment_intent_id: session.payment_intent
    )

    PaymentLinksMailer
      .customer_payment_link_received(booking, booking.payment_link_amount)
      .deliver_later

    PaymentLinksMailer
      .business_payment_link_received(booking, booking.payment_link_amount)
      .deliver_later

    Rails.logger.info(
      "Booking #{booking.id} payment updated. " \
        "Paid £#{payment_amount}. " \
        "Total paid £#{new_amount_paid}. " \
        "Status: #{payment_status}"
    )
  end
end