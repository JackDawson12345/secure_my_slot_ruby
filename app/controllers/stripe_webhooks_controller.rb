
class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    signature = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(
        payload,
        signature,
        ENV.fetch("STRIPE_WEBHOOK_SECRET")
      )
    rescue JSON::ParserError,
      Stripe::SignatureVerificationError => e
      Rails.logger.error(
        "Stripe webhook verification failed: #{e.message}"
      )
      return head :bad_request
    end

    case event.type
    when "checkout.session.completed"
      session = event.data.object
      metadata = session.metadata

      if metadata["payment_type"] == "payment_link"
        handle_payment_link_completed(session)
      elsif metadata["booking_hold_id"].present?
        handle_customer_booking_completed(
          session,
          event.account
        )
      else
        Rails.logger.info(
          "Stripe Checkout session #{session.id} " \
            "has no recognised payment type."
        )
      end
    end

    head :ok

  rescue StandardError => e
    Rails.logger.error(
      "Stripe webhook failed: #{e.class} - #{e.message}"
    )

    Rails.logger.error(
      Array(e.backtrace).first(20).join("\n")
    )

    head :internal_server_error
  end

  private

  # =========================================================
  # CUSTOMER MOBILE BOOKING
  # =========================================================

  def handle_customer_booking_completed(session, stripe_account_id)
    unless session.payment_status == "paid"
      Rails.logger.info(
        "Checkout #{session.id} is not paid."
      )
      return
    end

    hold_id = session.metadata["booking_hold_id"]

    booking_hold = BookingHold.find_by(id: hold_id)

    unless booking_hold
      raise ActiveRecord::RecordNotFound,
            "Booking hold #{hold_id} not found."
    end

    Rails.logger.info(
      "Processing paid booking hold #{booking_hold.id}"
    )

    booking = CustomerPaidBookingCompletion.new(
      booking_hold: booking_hold,
      checkout_session: session,
      stripe_account_id: stripe_account_id
    ).call

    Rails.logger.info(
      "Stripe payment processed successfully. " \
        "Booking ID: #{booking.id}, " \
        "Hold ID: #{booking_hold.id}, " \
        "Payment: #{booking.payment_status}"
    )
  end

  # =========================================================
  # EXISTING PAYMENT LINK FUNCTIONALITY
  # =========================================================

  def handle_payment_link_completed(session)
    return unless session.payment_status == "paid"

    booking = Booking.find_by(
      payment_link_checkout_session_id: session.id
    )

    unless booking
      Rails.logger.error(
        "No booking found for payment link session #{session.id}"
      )
      return
    end

    booking.with_lock do
      if booking.payment_link_payment_intent_id ==
         session.payment_intent

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
    end

    PaymentLinksMailer
      .customer_payment_link_received(
        booking,
        booking.payment_link_amount
      )
      .deliver_later

    PaymentLinksMailer
      .business_payment_link_received(
        booking,
        booking.payment_link_amount
      )
      .deliver_later

    Rails.logger.info(
      "Booking #{booking.id} payment updated. " \
        "Total paid £#{booking.amount_paid}. " \
        "Status: #{booking.payment_status}"
    )
  end
end
