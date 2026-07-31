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
end