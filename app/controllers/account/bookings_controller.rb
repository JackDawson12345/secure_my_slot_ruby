class Account::BookingsController < Account::BaseController
  PER_PAGE = 5

  STATUS_OPTIONS = %w[Confirmed Pending].freeze
  DATE_RANGE_OPTIONS = ["This week", "This month", "Last 3 months", "This year"].freeze
  TAB_OPTIONS = %w[All Upcoming Pending].freeze

  def index
    all_scope = current_user.bookings

    future_condition = [
      "date > :today OR (date = :today AND time >= :current_time)",
      { today: Date.current, current_time: Time.current }
    ]

    future_scope = all_scope.where(*future_condition)

    # --- Stats: upcoming/pending are future-only, completed/cancelled are all-time ---
    @upcoming_count   = future_scope.where(status: %w[confirmed pending]).count
    @pending_count    = future_scope.where(status: "pending").count
    @completed_count  = all_scope.where(status: "completed").count
    @cancelled_count  = all_scope.where(status: "cancelled").count

    # --- Next appointment: nearest confirmed booking in the future ---
    @next_booking = future_scope
                      .where(status: "confirmed")
                      .reorder(date: :asc, time: :asc)
                      .first

    # --- Filters ---
    @query      = params[:query].to_s.strip
    @status     = params[:status].presence
    @date_range = params[:date_range].presence
    @tab        = TAB_OPTIONS.include?(params[:tab]) ? params[:tab] : "All"

    # Base scope for the table is ALWAYS future-only — this page is for
    # upcoming bookings. Past/completed/cancelled bookings live on the
    # Booking History page.
    filtered_scope = future_scope.order(date: :asc, time: :asc)

    case @tab
    when "Upcoming"
      filtered_scope = filtered_scope.where(status: "confirmed")
    when "Pending"
      filtered_scope = filtered_scope.where(status: "pending")
    end

    if @query.present?
      filtered_scope = filtered_scope
                         .joins(:service, :business)
                         .where(
                           "LOWER(services.name) LIKE :q OR LOWER(businesses.business_name) LIKE :q",
                           q: "%#{@query.downcase}%"
                         )
    end

    if @status.present? && STATUS_OPTIONS.include?(@status)
      filtered_scope = filtered_scope.where(status: @status.downcase)
    end

    if @date_range.present? && DATE_RANGE_OPTIONS.include?(@date_range)
      from_date =
        case @date_range
        when "This week"     then Date.current.beginning_of_week
        when "This month"    then Date.current.beginning_of_month
        when "Last 3 months" then 3.months.ago.to_date
        when "This year"     then Date.current.beginning_of_year
        end

      filtered_scope = filtered_scope.where("date >= ?", from_date)
    end

    @total_bookings = filtered_scope.count

    # --- Pagination ---
    @per_page    = PER_PAGE
    @total_pages = [(@total_bookings.to_f / @per_page).ceil, 1].max

    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page = @total_pages if @page > @total_pages

    @bookings = filtered_scope
                  .limit(@per_page)
                  .offset((@page - 1) * @per_page)
  end

  def show
    @booking = Booking.find(params[:id])
  end

  def reschedule
    @booking = current_user.bookings
                           .includes(
                             :service,
                             business: :business_setting
                           )
                           .find(params[:id])
  end

  def reschedule_slots
    booking = current_user.bookings
                          .includes(:service, :business)
                          .find(params[:id])

    date = Date.parse(params[:date])

    slots = BookingAvailability.new(
      booking.business,
      booking.service,
      date
    ).call

    render json: {
      slots: slots
    }
  rescue ArgumentError
    render json: {
      slots: [],
      error: "Invalid date"
    }, status: :unprocessable_entity
  end

  def update_reschedule
    @booking = current_user.bookings.find(params[:id])

    date = Date.parse(params[:date])
    time = params[:time]

    available_slots = BookingAvailability.new(
      @booking.business,
      @booking.service,
      date
    ).call

    unless available_slots.include?(time)
      redirect_to account_reschedule_booking_path(@booking),
                  alert: "That appointment time is no longer available."
      return
    end

    @booking.update!(
      date: date,
      time: Time.zone.parse(time)
    )

    redirect_to account_show_booking_path(@booking),
                notice: "Your booking has been rescheduled successfully."
  rescue ArgumentError
    redirect_to account_reschedule_booking_path(@booking),
                alert: "Please select a valid date and time."
  end

  def cancel
    @booking = current_user.bookings
                           .includes(business: :business_setting)
                           .find(params[:id])

    settings = @booking.business.business_setting

    unless settings&.allow_customer_cancellations?
      redirect_to account_show_booking_path(@booking),
                  alert: "This business does not allow customer cancellations."
      return
    end

    if @booking.status == "cancelled"
      redirect_to account_show_booking_path(@booking),
                  alert: "This booking has already been cancelled."
      return
    end

    if @booking.status == "completed"
      redirect_to account_show_booking_path(@booking),
                  alert: "Completed bookings cannot be cancelled."
      return
    end

    appointment_time = Time.zone.local(
      @booking.date.year,
      @booking.date.month,
      @booking.date.day,
      @booking.time.hour,
      @booking.time.min
    )

    notice_hours = settings.cancellation_notice_hours.to_i
    cancellation_cutoff = appointment_time - notice_hours.hours

    if Time.current >= cancellation_cutoff
      redirect_to account_show_booking_path(@booking),
                  alert: "This booking can no longer be cancelled because it is within the #{notice_hours}-hour cancellation period."
      return
    end

    @booking.update!(
      status: "cancelled"
    )

    if @booking.business.business_setting.cancellation_notifications
      BookingMailer
        .with(booking: @booking)
        .booking_cancelled
        .deliver_later
    end


    redirect_to account_show_booking_path(@booking),
                notice: "Your booking has been cancelled."
  end
end