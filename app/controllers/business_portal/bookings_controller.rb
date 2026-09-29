# app/controllers/business_portal/bookings_controller.rb

class BusinessPortal::BookingsController < BusinessPortal::BaseController
  def index
    @business = current_user.business

    bookings = @business.bookings.includes(:user, :service)

    today = Date.current
    current_time = Time.current

    # ----------------------------------------
    # Statistics
    # ----------------------------------------

    todays_bookings = @business.bookings.where(date: today)

    @today_count = todays_bookings.count
    @today_confirmed_count = todays_bookings.where(status: :confirmed).count
    @today_pending_count = todays_bookings.where(status: :pending).count

    @upcoming_count = @business.bookings
                               .where(date: today..(today + 7.days))
                               .where(
                                 "date > :today OR (date = :today AND time >= :current_time)",
                                 today: today,
                                 current_time: current_time
                               )
                               .count

    @completed_count = @business.bookings
                                .where(status: :completed)
                                .where(date: today.beginning_of_month..today.end_of_month)
                                .count

    @cancelled_count = @business.bookings
                                .where(status: :cancelled)
                                .where(date: today.beginning_of_month..today.end_of_month)
                                .count

    # ----------------------------------------
    # Services for filter dropdown
    # ----------------------------------------

    @services = @business.services.order(:name)

    # ----------------------------------------
    # Base booking scope
    # ----------------------------------------

    bookings_scope = bookings.order(date: :asc, time: :asc)

    # ----------------------------------------
    # Status filter
    # ----------------------------------------

    if params[:status].present? &&
       %w[confirmed pending completed cancelled].include?(params[:status])

      bookings_scope = bookings_scope.where(status: params[:status])
    end

    # ----------------------------------------
    # Search
    # ----------------------------------------

    if params[:q].present?
      search = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

      bookings_scope = bookings_scope
                         .joins(:user, :service)
                         .where(
                           <<~SQL.squish,
                           users.first_name ILIKE :search
                           OR users.last_name ILIKE :search
                           OR users.email ILIKE :search
                           OR services.name ILIKE :search
                         SQL
                           search: search
                         )
    end

    # ----------------------------------------
    # Service filter
    # ----------------------------------------

    if params[:service_id].present?
      bookings_scope = bookings_scope.where(service_id: params[:service_id])
    end

    # ----------------------------------------
    # Date filters
    # ----------------------------------------

    if params[:date_from].present?
      bookings_scope = bookings_scope.where(
        "bookings.date >= ?",
        params[:date_from]
      )
    end

    if params[:date_to].present?
      bookings_scope = bookings_scope.where(
        "bookings.date <= ?",
        params[:date_to]
      )
    end

    # ----------------------------------------
    # Pagination
    # ----------------------------------------

    @per_page = 10

    @current_page = params[:page].to_i
    @current_page = 1 if @current_page < 1

    @total_bookings = bookings_scope.count

    @total_pages =
      if @total_bookings.positive?
        (@total_bookings.to_f / @per_page).ceil
      else
        1
      end

    @current_page = @total_pages if @current_page > @total_pages

    @bookings = bookings_scope
                  .offset((@current_page - 1) * @per_page)
                  .limit(@per_page)

    @booking_start =
      if @total_bookings.zero?
        0
      else
        ((@current_page - 1) * @per_page) + 1
      end

    @booking_end = [
      @current_page * @per_page,
      @total_bookings
    ].min
  end

  def add_booking
    @business = current_user.business
  end

  def show
    @business = current_user.business
    @booking = @business.bookings.find(params[:id])
    @agreements = @business.agreements
    @email_templates = @business.email_templates.where(custom: true)
  end

  def agreements_show
    @agreement_status = AgreementStatus.find_by(token: params[:token])

    return redirect_to root_path unless @agreement_status

    @agreement = @agreement_status.agreement
    @booking = @agreement_status.booking
  end

  def agreements_pdf

    @agreement_status = AgreementStatus.find_by(token: params[:token])

    return redirect_to root_path unless @agreement_status

    @agreement = @agreement_status.agreement
    @booking = @agreement_status.booking


    respond_to do |format|

      format.pdf do

        render pdf: "#{@agreement.name}",
               template: "business_portal/bookings/agreement_pdf",
               layout: "pdf",
               disposition: "attachment"

      end

    end

  end

  def update_status
    @business = current_user.business
    @booking = @business.bookings.find(params[:id])

    new_status = params[:status]

    allowed_transitions = {
      "pending"   => ["confirmed"],
      "confirmed" => ["completed"],
      "completed" => ["confirmed"]
    }

    unless allowed_transitions.fetch(@booking.status, []).include?(new_status)
      redirect_to business_booking_path(@booking),
                  alert: "That booking status change is not allowed."
      return
    end

    if @booking.update(status: new_status)
      message =
        case new_status
        when "confirmed"
          "Booking marked as confirmed."
        when "completed"
          "Booking marked as completed."
        else
          "Booking status updated."
        end

      if @booking.user.customer_setting.booking_changes
        BookingMailer
          .with(booking: @booking)
          .status_changed
          .deliver_now
        SendBookingStatusChangeSmsJob.perform_later(@booking.id)
      end

      redirect_to business_booking_path(@booking), notice: message
    else
      redirect_to business_booking_path(@booking),
                  alert: "Could not update the booking status."
    end
  end

  def create
    @business = current_user.business

    begin
      Booking.transaction do
        params = permitted_booking_params

        @user = find_or_build_user(params)

        new_user = @user.new_record?

        @user.save!

        if new_user
          @user.create_customer_setting!(
            phone_number: params[:phone_number],
            preferred_name: [
              params[:first_name],
              params[:last_name]
            ].compact.join(" "),
            booking_confirmations: true,
            appointment_reminders: true,
            booking_changes: true,
            offers_and_service_updates: false,
            reminder_timing: "60",
            reminder_method: "sms"
          )

          CustomerAccountMailer
            .welcome_with_password_setup(@user)
            .deliver_later
        end

        @booking = @business.bookings.new(
          user: @user,
          service_id: params[:service_id],
          date: params[:date],
          time: params[:time],
          notes: params[:notes],
          status: "confirmed"
        )

        @booking.save!
      end

      redirect_to business_bookings_path,
                  notice: "Booking added successfully."

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.record.errors.full_messages

      flash.now[:alert] =
        "Could not create booking. Please check the details below."

      render :add_booking,
             status: :unprocessable_entity
    end
  end

  def calendar

  end

  def consultation_pdf
    @booking = current_user.business.bookings.find(params[:id])

    respond_to do |format|
      format.pdf do
        render pdf: "consultation-form-#{@booking.id}",
               template: "business_portal/bookings/consultation_pdf",
               layout: "pdf",
               disposition: "attachment",
               page_size: "A4",
               margin: {
                 top: 15,
                 bottom: 15,
                 left: 15,
                 right: 15
               }
      end
    end
  end

  def find
    bookings = current_user.business.bookings.where(status: ["pending", "confirmed", "completed"])

    render json: bookings.map { |booking|

      start_time = booking.time.strftime("%H:%M")

      start_datetime = "#{booking.date}T#{start_time}"

      end_datetime = booking.date.to_time +
                     booking.time.seconds_since_midnight.seconds +
                     booking.service.minutes_duration.minutes


      {
        id: booking.id,

        title: "#{booking.user.first_name} #{booking.user.last_name}",

        start: start_datetime,

        end: end_datetime.strftime("%Y-%m-%dT%H:%M:%S"),

        backgroundColor: booking.status == "confirmed" ? "#16a34a" : "#f59e0b",

        borderColor: "transparent",

        extendedProps: {
          service: booking.service.name,
          status: booking.status,
          price: booking.service.price
        }
      }

    }
  end

  def create_payment_link
    business = current_user.business
    booking = business.bookings.find(params[:id])

    # Redirect if a payment link already exists
    if booking.stripe_payment_link.present?
      redirect_to business_payment_link_path(booking)
      return
    end

    unless business.stripe_connected?
      redirect_to business_booking_path(booking),
                  alert: "Payment system not available."
      return
    end

    outstanding_amount = booking.amount.to_d - booking.amount_paid.to_d

    if outstanding_amount <= 0
      redirect_to business_booking_path(booking),
                  alert: "This booking has already been paid."
      return
    end

    stripe_amount = (outstanding_amount * 100).round.to_i

    session = Stripe::Checkout::Session.create(
      {
        mode: "payment",

        customer_email: booking.user.email,

        line_items: [
          {
            price_data: {
              currency: "gbp",
              product_data: {
                name: "#{booking.service.name} - Booking ##{booking.id}"
              },
              unit_amount: stripe_amount
            },
            quantity: 1
          }
        ],

        metadata: {
          booking_id: booking.id,
          payment_type: "payment_link"
        },

        success_url: payment_success_url(booking),
        cancel_url: root_url
      },
      {
        stripe_account: business.stripe_account_id
      }
    )

    booking.update!(
      payment_link_checkout_session_id: session.id,
      stripe_payment_link: session.url,
      payment_link_amount: outstanding_amount
    )

    redirect_to business_payment_link_path(booking)
  end

  def send_payment_link_email

    business = current_user.business
    booking = business.bookings.find(params[:id])

    PaymentLinksMailer
      .send_customer_payment_link(
        booking,
        booking.stripe_payment_link,
        booking.payment_link_amount
      )
      .deliver_later

    redirect_to business_booking_path(booking),
                notice: "Payment Link Email Sent."

  end

  def send_payment_link_sms
    booking = current_user.business.bookings.find(params[:id])

    if booking.user.phone_number.blank?
      redirect_to business_booking_path(booking),
                  alert: "This customer does not have a phone number."
      return
    end

    if booking.stripe_payment_link.blank?
      redirect_to business_booking_path(booking),
                  alert: "No payment link has been created for this booking."
      return
    end

    message = <<~SMS
    Hi #{booking.user.first_name},

    You can make payment for your booking with #{booking.business.business_name} using the link below:

    #{booking.stripe_payment_link}

    Thank you.
  SMS

    result = SmsService.send_message(
      to: booking.user.phone_number,
      body: message
    )

    if result
      redirect_to business_booking_path(booking),
                  notice: "Payment link sent via SMS."
    else
      redirect_to business_booking_path(booking),
                  alert: "Unable to send the payment link via SMS."
    end
  end

  def no_show
    @booking = current_user.business.bookings.find(params[:id])

    @business_customer = BusinessCustomer.find_by(
      business: current_user.business,
      user: @booking.user
    )

    @has_saved_card = @business_customer&.stripe_customer_id.present?
  end

  def charge_no_show_fee

    booking = current_user.business.bookings.find(params[:id])

    if booking.no_show_fee_charged_at.present? ||
       booking.no_show_payment_intent_id.present?

      redirect_to business_booking_path(booking),
                  alert: "A no show fee has already been charged for this booking."
      return
    end

    no_show_fee = BigDecimal(params[:no_show_fee].to_s)

    if no_show_fee <= 0
      redirect_to business_no_show_path(booking),
                  alert: "Please enter a valid no show fee."
      return
    end

    business_customer = BusinessCustomer.find_by(
      business: current_user.business,
      user: booking.user
    )

    unless business_customer&.stripe_customer_id.present?
      redirect_to business_no_show_path(booking),
                  alert: "This customer doesn't have a saved payment method."
      return
    end

    payment_methods = Stripe::PaymentMethod.list(
      {
        customer: business_customer.stripe_customer_id,
        type: "card"
      },
      {
        stripe_account: current_user.business.stripe_account_id
      }
    )

    payment_method = payment_methods.data.first

    unless payment_method
      redirect_to business_no_show_path(booking),
                  alert: "This customer doesn't have a saved payment method."
      return
    end

    payment_intent = Stripe::PaymentIntent.create(
      {
        amount: (no_show_fee * 100).round.to_i,
        currency: "gbp",

        customer: business_customer.stripe_customer_id,
        payment_method: payment_method.id,

        off_session: true,
        confirm: true,

        description: "No show fee for Booking ##{booking.id}",

        metadata: {
          booking_id: booking.id.to_s,
          business_id: current_user.business.id.to_s,
          payment_type: "no_show_fee"
        }
      },
      {
        stripe_account: current_user.business.stripe_account_id,
        idempotency_key: "booking-#{booking.id}-no-show"
      }
    )

    booking.update!(
      status: "no_show",
      no_show_fee: no_show_fee,
      no_show_payment_intent_id: payment_intent.id,
      no_show_fee_charged_at: Time.current
    )

    redirect_to business_booking_path(booking),
                notice: "The £#{format('%.2f', no_show_fee)} no show fee was charged successfully."

  rescue ArgumentError
    redirect_to business_no_show_path(params[:id]),
                alert: "Please enter a valid no show fee."

  rescue Stripe::CardError => e
    Rails.logger.warn(
      "No show charge declined for booking #{params[:id]}: #{e.message}"
    )

    redirect_to business_no_show_path(params[:id]),
                alert: "The no show fee couldn't be charged. #{e.message}"

  rescue Stripe::StripeError => e
    Rails.logger.error(
      "Stripe no show charge error for booking #{params[:id]}: #{e.class} - #{e.message}"
    )

    redirect_to business_no_show_path(params[:id]),
                alert: "The no show fee couldn't be charged. Please try again."
  end

  def payment_link
    @business = current_user.business
    @booking = @business.bookings.find(params[:id])

    unless @booking.stripe_payment_link.present?
      redirect_to business_booking_path(@booking),
                  alert: "No payment link has been created for this booking."
    end
  end

  def mark_as_paid
    booking = current_user.business.bookings.find(params[:id])

    booking.update!(
      amount_paid: booking.amount,
      payment_status: "paid"
    )

    redirect_to business_booking_path(booking),
                notice: "Booking marked as paid."
  end

  private

  def find_or_build_user(attrs)
    user = User.find_or_initialize_by(email: attrs[:email])

    user.first_name = attrs[:first_name] if attrs[:first_name].present?
    user.last_name = attrs[:last_name] if attrs[:last_name].present?
    user.phone_number = attrs[:phone_number] if attrs[:phone_number].present?

    if user.new_record?
      password = generate_customer_password

      user.password = password
      user.password_confirmation = password
      user.role = :customer

      user.terms_accepted = true
      user.terms_accepted_at = Time.current if user.respond_to?(:terms_accepted_at=)
    end

    user
  end

  def generate_customer_password
    [
      ("A".."Z").to_a.sample,
      ("0".."9").to_a.sample,
      ["!", "@", "#", "$", "%"].sample,
      SecureRandom.hex(8)
    ].join
  end

  def permitted_booking_params
    params.require(:booking).permit(
      :service_id,
      :date,
      :time,
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :notes
    )
  end
end