
class CustomerPaidBookingCompletion
  class VerificationError < StandardError; end

  def initialize(booking_hold:, checkout_session:, stripe_account_id:)
    @booking_hold = booking_hold
    @session = checkout_session
    @stripe_account_id = stripe_account_id
  end

  def call
    booking = nil
    created = false

    BookingHold.transaction do
      @booking_hold.lock!

      verify_payment!

      if @booking_hold.booking_id.present?
        booking = @booking_hold.booking

        unless booking.stripe_checkout_session_id == @session.id
          raise VerificationError,
                "Booking was completed with another Stripe session."
        end
      else
        booking = create_booking!

        @booking_hold.update!(
          booking: booking,
          completed_at: Time.current
        )

        created = true
      end
    end

    if created
      Rails.logger.info(
        "Customer booking #{booking.id} created " \
          "from paid hold #{@booking_hold.id}"
      )

      # =====================================================
      # EXISTING SMS AND EMAIL NOTIFICATIONS
      # =====================================================

      send_booking_confirmations(booking)

      # =====================================================
      # EXPO PUSH NOTIFICATIONS
      # =====================================================

      safely_enqueue(
        "Expo push notifications",
        booking.id
      ) do
        BookingNotificationService.created(
          booking
        )

        Rails.logger.info(
          "PUSH: Notifications queued for paid booking #{booking.id}"
        )
      end
    end

    booking
  end

  private

  def verify_payment!
    unless @session.id.to_s ==
           @booking_hold.stripe_checkout_session_id.to_s &&
           @session.id.present?
      raise VerificationError, "Checkout session mismatch."
    end

    unless @session.status == "complete" &&
           @session.payment_status == "paid"
      raise VerificationError, "Checkout payment is not complete."
    end

    unless @session.mode == "payment"
      raise VerificationError, "Unexpected Checkout session mode."
    end

    unless @stripe_account_id.to_s ==
           @booking_hold.business.stripe_account_id.to_s &&
           @stripe_account_id.present?
      raise VerificationError, "Stripe account mismatch."
    end

    metadata = @session.metadata

    expected = {
      "booking_hold_id" => @booking_hold.id,
      "business_id" => @booking_hold.business_id,
      "service_id" => @booking_hold.service_id,
      "customer_id" => @booking_hold.user_id
    }

    expected.each do |key, value|
      unless metadata[key].to_s == value.to_s
        raise VerificationError, "Payment metadata mismatch: #{key}"
      end
    end

    unless @session.currency == "gbp"
      raise VerificationError, "Unexpected payment currency."
    end

    service = @booking_hold.service

    price =
      if service.deposit_enabled? &&
         service.deposit.present? &&
         service.deposit.to_d.positive?
        service.deposit.to_d
      else
        service.price.to_d
      end

    expected_pence = (price * 100).round.to_i

    unless @session.amount_total.to_i == expected_pence
      raise VerificationError, "Stripe payment amount mismatch."
    end

    if @session.payment_intent.blank?
      raise VerificationError, "Missing Stripe PaymentIntent."
    end
  end

  def create_booking!
    business = @booking_hold.business

    status =
      if business.business_setting.automatically_confirm_bookings?
        "confirmed"
      else
        "pending"
      end

    amount_paid = BigDecimal(
                    @session.amount_total.to_s
                  ) / 100

    total_amount = @booking_hold.amount.to_d

    Booking.create!(
      user: @booking_hold.user,
      business: business,
      service: @booking_hold.service,
      agent_id: @booking_hold.agent_id,
      date: @booking_hold.date,
      time: @booking_hold.time,
      notes: @booking_hold.notes,
      status: status,
      amount: total_amount,
      amount_paid: amount_paid,
      payment_status: (
        amount_paid >= total_amount ?
          "paid" : "awaiting_payment"
      ),
      stripe_checkout_session_id: @session.id,
      stripe_payment_intent_id: @session.payment_intent
    )
  end

  def send_booking_confirmations(booking)
    customer_settings = booking.user.customer_setting
    business_settings = booking.business.business_setting

    if customer_settings&.booking_confirmations
      safely_enqueue("Customer booking SMS", booking.id) do
        SendBookingConfirmationSmsJob.perform_later(booking.id)
      end

      safely_enqueue("Customer booking email", booking.id) do
        BookingMailer
          .with(booking: booking)
          .customer_booking_confirmation
          .deliver_later
      end
    end

    if business_settings&.new_booking_notifications
      safely_enqueue("Business booking SMS", booking.id) do
        SendBusinessBookingConfirmationSmsJob.perform_later(booking.id)
      end

      safely_enqueue("Business booking email", booking.id) do
        BookingMailer
          .with(booking: booking)
          .business_booking_notification
          .deliver_later
      end
    end
  end

  def safely_enqueue(description, booking_id)
    yield
  rescue StandardError => e
    Rails.logger.error(
      "#{description} failed for booking #{booking_id}: " \
        "#{e.class} - #{e.message}"
    )
  end
end
