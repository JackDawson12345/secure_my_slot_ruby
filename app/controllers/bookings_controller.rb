class BookingsController < ApplicationController
  layout 'business_site'
  def slots
    business = Business.find(params[:business_id])
    service = business.services.find(params[:service_id])
    date = Date.parse(params[:date])

    slots = BookingAvailability.new(
      business,
      service,
      date
    ).call

    render json: slots
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Business or service not found." },
           status: :not_found
  rescue Date::Error
    render json: { error: "Invalid date." },
           status: :unprocessable_entity
  end

  def create
    service = Service.find(booking_params[:service_id])
    business = service.business
    user = find_or_create_user

    booking = Booking.new(
      user: user,
      business: business,
      service: service,
      date: booking_params[:date],
      time: booking_params[:time],
      notes: booking_params[:notes],
      status: "pending",
      payment_status: business.stripe_ready? ? "awaiting_payment" : "not_required"
    )

    if booking.save
      if business.stripe_ready?
        redirect_to_stripe_checkout(
          booking: booking,
          business: business,
          service: service
        )
      else
        SendBookingConfirmationSmsJob.perform_later(booking.id)
        SendBusinessBookingConfirmationSmsJob.perform_later(booking.id)

        redirect_to(
          business_site_url(
            subdomain: business.page_address
          ),
          notice: "Your booking has been requested.",
          allow_other_host: true
        )
      end
    else
      redirect_back(
        fallback_location: business_site_url(
          subdomain: business.page_address
        ),
        alert: booking.errors.full_messages.join(", ")
      )
    end
  rescue ActiveRecord::RecordNotFound
    redirect_back(
      fallback_location: root_path,
      alert: "The selected service could not be found."
    )
  rescue ActiveRecord::RecordInvalid => e
    redirect_back(
      fallback_location: root_path,
      alert: e.record.errors.full_messages.join(", ")
    )
  rescue Stripe::StripeError => e
    Rails.logger.error(
      "Stripe Checkout error: #{e.class} - #{e.message}"
    )

    booking&.update(payment_status: "payment_failed")

    redirect_to(
      business_site_url(
        subdomain: business.page_address
      ),
      alert: "Your booking was created, but Stripe payment could not be started.",
      allow_other_host: true
    )
  end

  def payment_success
    @booking = Booking.find(params[:id])

    unless valid_payment_session?(@booking)
      redirect_to(
        business_site_url(
          subdomain: @booking.business.page_address
        ),
        alert: "We couldn't confirm your payment.",
        allow_other_host: true
      )

      return
    end

    checkout_session = retrieve_checkout_session(
      @booking,
      params[:session_id]
    )

    sms_already_sent = @booking.payment_status == "paid"

    @booking.update!(
      stripe_payment_intent_id: checkout_session.payment_intent,
      payment_status: "paid",
      amount_paid: amount_from_stripe(checkout_session.amount_total)
    )

    unless sms_already_sent
      SendBookingConfirmationSmsJob.perform_later(@booking.id)
    end

    render :payment_success
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path,
                alert: "The booking could not be found."
  rescue Stripe::StripeError => e
    Rails.logger.error(
      "Stripe payment success error: #{e.class} - #{e.message}"
    )

    redirect_to(
      business_site_url(
        subdomain: @booking.business.page_address
      ),
      alert: "We couldn't confirm your payment.",
      allow_other_host: true
    )
  end

  private

  def find_or_create_user
    email = booking_params[:email].to_s.downcase.strip

    user = User.find_or_initialize_by(email: email)

    user.assign_attributes(
      first_name: booking_params[:first_name],
      last_name: booking_params[:last_name],
      phone_number: booking_params[:phone_number]
    )

    if user.new_record?
      user.assign_attributes(
        password: SecureRandom.hex(16),
        role: :customer,
        terms_accepted: booking_params[:terms_accepted]
      )
    end

    user.save!
    user
  end

  def redirect_to_stripe_checkout(booking:, business:, service:)
    success_url = payment_success_booking_url(
      booking,
      host: request.host,
      port: request.optional_port,
      protocol: request.protocol
    )

    if service.deposit_enabled == true
      price = service.deposit
      service_name = service.name + ' (Deposit)'
    else
      price = service.price
      service_name = service.name
    end

    # Stripe replaces this placeholder with the real Checkout Session ID.
    # It must be appended manually so Rails does not encode the braces.
    success_url += "?session_id={CHECKOUT_SESSION_ID}"

    cancel_url = business_site_url(
      subdomain: business.page_address,
      payment_cancelled: true
    )

    checkout_session = Stripe::Checkout::Session.create(
      {
        mode: "payment",

        customer_email: booking.user.email,

        line_items: [
          {
            price_data: {
              currency: "gbp",

              product_data: {
                name: service_name,
                description: booking_description(booking)
              },

              unit_amount: price_in_pence(price)
            },

            quantity: 1
          }
        ],

        metadata: {
          booking_id: booking.id.to_s,
          business_id: business.id.to_s,
          service_id: service.id.to_s
        },

        payment_intent_data: {
          metadata: {
            booking_id: booking.id.to_s,
            business_id: business.id.to_s
          }
        },

        success_url: success_url,
        cancel_url: cancel_url
      },
      {
        stripe_account: business.stripe_account_id,
        idempotency_key: "booking-#{booking.id}-checkout"
      }
    )

    booking.update!(
      stripe_checkout_session_id: checkout_session.id
    )

    redirect_to checkout_session.url,
                allow_other_host: true,
                status: :see_other
  end

  def valid_payment_session?(booking)
    session_id = params[:session_id].to_s

    return false if session_id.blank?
    return false if booking.stripe_checkout_session_id.blank?
    return false unless session_id == booking.stripe_checkout_session_id

    checkout_session = retrieve_checkout_session(
      booking,
      session_id
    )

    checkout_session.payment_status == "paid"
  end

  def retrieve_checkout_session(booking, session_id)
    Stripe::Checkout::Session.retrieve(
      session_id,
      {
        stripe_account: booking.business.stripe_account_id
      }
    )
  end

  def price_in_pence(price)
    (BigDecimal(price.to_s) * 100).round.to_i
  end

  def booking_description(booking)
    date = booking.date.strftime("%d %B %Y")
    time = booking.time.strftime("%I:%M %p")

    "#{date} at #{time}"
  end

  def amount_from_stripe(amount_in_pence)
    BigDecimal(amount_in_pence.to_s) / 100
  end

  def booking_params
    params.require(:booking).permit(
      :service_id,
      :date,
      :time,
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :notes,
      :terms_accepted
    )
  end
end