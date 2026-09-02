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