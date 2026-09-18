class BookingsController < ApplicationController
  layout "business_site"

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
    render json: {
      error: "Business or service not found."
    }, status: :not_found

  rescue Date::Error
    render json: {
      error: "Invalid date."
    }, status: :unprocessable_entity
  end

  def create

    service = Service.find(booking_params[:service_id])
    business = service.business
    user, new_customer_account = find_or_create_user

    coupon = business.service_coupons.find do |service_coupon|
      service_coupon.code.strip.casecmp(booking_params['service_coupon'].strip).zero?
    end

    coupon_works = coupon.active? &&
      (coupon.expires_at.nil? || coupon.expires_at.future?) &&
      coupon.services.include?(service.id.to_s)

    if business.stripe_ready? && payment_required_for?(service)
      create_stripe_booking_hold(
        business: business,
        service: service,
        user: user,
        new_customer_account: new_customer_account,
        coupon: coupon,
        coupon_works: coupon_works
      )
    else
      create_booking_without_payment(
        business: business,
        service: service,
        user: user,
        new_customer_account: new_customer_account,
        coupon: coupon,
        coupon_works: coupon_works
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

    redirect_to(
      business_site_url(
        subdomain: business.page_address
      ),
      alert: "We couldn't start your payment. Please try again.",
      allow_other_host: true
    )
  end

  def confirmation
    @booking = Booking.find(params[:id])
    @business = @booking.business

    render :payment_success

  rescue ActiveRecord::RecordNotFound
    redirect_to(
      root_path,
      alert: "The booking could not be found."
    )
  end

  def payment_success
    booking_hold = BookingHold.find(params[:id])

    if booking_hold.booking.present?
      @booking = booking_hold.booking

      return render :payment_success
    end

    unless valid_payment_session?(
      booking_hold,
      params[:session_id]
    )
      return redirect_to(
        business_site_url(
          subdomain: booking_hold.business.page_address
        ),
        alert: "We couldn't confirm your payment.",
        allow_other_host: true
      )
    end

    checkout_session = retrieve_checkout_session(
      booking_hold,
      params[:session_id]
    )

    @booking = complete_paid_booking!(
      booking_hold: booking_hold,
      checkout_session: checkout_session,
      amount: booking_hold.amount,
      coupon: booking_hold.coupon
    )

    render :payment_success

  rescue ActiveRecord::RecordNotFound
    redirect_to(
      root_path,
      alert: "The payment session could not be found."
    )

  rescue Stripe::StripeError => e
    Rails.logger.error(
      "Stripe payment success error: #{e.class} - #{e.message}"
    )

    redirect_to(
      root_path,
      alert: "We couldn't confirm your payment."
    )
  end

  private

  def create_stripe_booking_hold(
    business:,
    service:,
    user:,
    new_customer_account:,
    coupon:,
    coupon_works:
  )

    if coupon_works == true

      original_price = service.price.to_d

      discounted_price =
        case coupon.coupon_type

        when "percentage"
          original_price -
            (original_price * (coupon.discount / 100))

        when "fixed"
          original_price - coupon.discount

        else
          original_price
        end

      discounted_price = 0 if discounted_price < 0
      amount = discounted_price

      coupon_code = coupon.id

    else
      amount = service.price.to_d

      coupon_code = nil
    end

    booking_hold = BookingHold.create!(
      user: user,
      business: business,
      service: service,
      date: booking_params[:date],
      time: booking_params[:time],
      notes: booking_params[:notes],
      expires_at: 30.minutes.from_now,
      amount: amount,
      coupon: coupon_code
    )

    redirect_to_stripe_checkout(
      booking_hold: booking_hold,
      business: business,
      service: service,
      new_customer_account: new_customer_account
    )

  rescue Stripe::StripeError
    booking_hold&.destroy
    raise
  end

  def create_booking_without_payment(
    business:,
    service:,
    user:,
    new_customer_account:,
    coupon:,
    coupon_works:
  )
    if coupon_works == true

      original_price = service.price.to_d

      discounted_price =
        case coupon.coupon_type

        when "percentage"
          original_price -
            (original_price * (coupon.discount / 100))

        when "fixed"
          original_price - coupon.discount

        else
          original_price
        end

      discounted_price = 0 if discounted_price < 0
      amount = discounted_price

      coupon_code = coupon.id

    else
      amount = service.price.to_d

      coupon_code = nil
    end

    booking = Booking.new(
      user: user,
      business: business,
      service: service,
      date: booking_params[:date],
      time: booking_params[:time],
      notes: booking_params[:notes],
      payment_status: "not_required",
      amount: amount,
      amount_paid: 0,
      coupon: coupon_code
    )

    booking.status =
      if business.business_setting.automatically_confirm_bookings?
        "confirmed"
      else
        "pending"
      end

    booking.save!

    if new_customer_account
      CustomerAccountMailer
        .welcome_with_password_setup(user)
        .deliver_later
    end

    user_settings = user.customer_setting || user.create_customer_setting!

    if user_settings.booking_confirmations
      SendBookingConfirmationSmsJob.perform_later(
        booking.id
      )
      BookingMailer
        .with(booking: booking)
        .customer_booking_confirmation
        .deliver_later
    end
    if business.business_setting.new_booking_notifications
      SendBusinessBookingConfirmationSmsJob.perform_later(
        booking.id
      )
      BookingMailer
        .with(booking: booking)
        .business_booking_notification
        .deliver_later
    end

    redirect_to(
      booking_confirmation_url(
        booking,
        subdomain: business.page_address
      ),
      allow_other_host: true,
      status: :see_other
    )
  end

  def find_or_create_user
    email = booking_params[:email].to_s.downcase.strip

    user = User.find_or_initialize_by(
      email: email
    )

    new_customer_account = user.new_record?

    user.assign_attributes(
      first_name: booking_params[:first_name],
      last_name: booking_params[:last_name],
      phone_number: booking_params[:phone_number]
    )

    if new_customer_account
      user.assign_attributes(
        password: generate_customer_password,
        role: :customer,
        terms_accepted: booking_params[:terms_accepted]
      )
    end

    user.save!

    user.create_customer_setting! unless user.customer_setting

    [user, new_customer_account]
  end

  def generate_customer_password
    [
      ("A".."Z").to_a.sample,
      ("0".."9").to_a.sample,
      ["!", "@", "#", "$", "%"].sample,
      SecureRandom.hex(8)
    ].join
  end

  def payment_required_for?(service)
    amount_due =
      if service.deposit_enabled?
        service.deposit.to_d
      else
        service.price.to_d
      end

    amount_due.positive?
  end

  def redirect_to_stripe_checkout(
    booking_hold:,
    business:,
    service:,
    new_customer_account:,
    amount:,
    coupon:
  )
    success_url = payment_success_booking_hold_url(
      booking_hold,
      host: request.host,
      port: request.optional_port,
      protocol: request.protocol
    )

    success_url += "?session_id={CHECKOUT_SESSION_ID}"

    if service.deposit_enabled?
      price = service.deposit
      service_name = "#{service.name} (Deposit)"
    else
      price = amount
      service_name = service.name
    end

    cancel_url = business_site_url(
      subdomain: business.page_address,
      payment_cancelled: true
    )

    checkout_session = Stripe::Checkout::Session.create(
      {
        mode: "payment",

        customer_email: booking_hold.user.email,

        line_items: [
          {
            price_data: {
              currency: "gbp",

              product_data: {
                name: service_name,
                description: booking_hold_description(
                  booking_hold
                )
              },

              unit_amount: price_in_pence(price)
            },

            quantity: 1
          }
        ],

        metadata: {
          booking_hold_id: booking_hold.id.to_s,
          business_id: business.id.to_s,
          service_id: service.id.to_s,
          new_customer_account: new_customer_account.to_s
        },

        payment_intent_data: {
          metadata: {
            booking_hold_id: booking_hold.id.to_s,
            business_id: business.id.to_s
          }
        },

        success_url: success_url,
        cancel_url: cancel_url,

        expires_at: 30.minutes.from_now.to_i
      },
      {
        stripe_account: business.stripe_account_id,

        idempotency_key:
          "booking-hold-#{booking_hold.id}-checkout"
      }
    )

    booking_hold.update!(
      stripe_checkout_session_id: checkout_session.id
    )

    redirect_to(
      checkout_session.url,
      allow_other_host: true,
      status: :see_other
    )
  end

  def complete_paid_booking!(
    booking_hold:,
    checkout_session:
  )
    booking = nil
    booking_created = false

    BookingHold.transaction do
      booking_hold.lock!

      if booking_hold.booking.present?
        booking = booking_hold.booking
        next
      end

      unless checkout_session.payment_status == "paid"
        raise Stripe::StripeError,
              "Checkout Session has not been paid."
      end

      status =
        if booking_hold.business
                       .business_setting
                       .automatically_confirm_bookings?
          "confirmed"
        else
          "pending"
        end

      booking = Booking.create!(
        user: booking_hold.user,
        business: booking_hold.business,
        service: booking_hold.service,
        date: booking_hold.date,
        time: booking_hold.time,
        notes: booking_hold.notes,
        status: status,
        payment_status: "paid",
        stripe_checkout_session_id: checkout_session.id,
        stripe_payment_intent_id: checkout_session.payment_intent,
        amount_paid: amount_from_stripe(
          checkout_session.amount_total
        ),
        amount: booking_hold.amount,
        coupon: booking_hold.coupon
      )

      booking_hold.update!(
        booking: booking,
        completed_at: Time.current
      )

      booking_created = true
    end

    if booking_created
      if checkout_session.metadata.new_customer_account == "true"
        CustomerAccountMailer
          .welcome_with_password_setup(booking.user)
          .deliver_later
      end

      user_settings =
        booking.user.customer_setting ||
        booking.user.create_customer_setting!

      if user_settings.booking_confirmations
        SendBookingConfirmationSmsJob.perform_later(
          booking.id
        )

        BookingMailer
          .with(booking: booking)
          .customer_booking_confirmation
          .deliver_later
      end

      if booking.business.business_setting.new_booking_notifications
        SendBusinessBookingConfirmationSmsJob.perform_later(
          booking.id
        )

        BookingMailer
          .with(booking: booking)
          .business_booking_notification
          .deliver_later
      end
    end

    booking
  end

  def valid_payment_session?(booking_hold, session_id)
    session_id = session_id.to_s

    return false if session_id.blank?

    return false if booking_hold
                      .stripe_checkout_session_id
                      .blank?

    return false unless ActiveSupport::SecurityUtils.secure_compare(
      session_id,
      booking_hold.stripe_checkout_session_id
    )

    checkout_session = retrieve_checkout_session(
      booking_hold,
      session_id
    )

    return false unless checkout_session.payment_status == "paid"

    booking_hold_id =
      checkout_session.metadata.booking_hold_id.to_s

    booking_hold_id == booking_hold.id.to_s
  end

  def retrieve_checkout_session(booking_hold, session_id)
    Stripe::Checkout::Session.retrieve(
      session_id,
      {
        stripe_account:
          booking_hold.business.stripe_account_id
      }
    )
  end

  def price_in_pence(price)
    (BigDecimal(price.to_s) * 100).round.to_i
  end

  def booking_hold_description(booking_hold)
    date = booking_hold.date.strftime("%d %B %Y")
    time = booking_hold.time.strftime("%I:%M %p")

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
      :terms_accepted,
      :service_coupon,
      :applied_coupon
    )
  end
end