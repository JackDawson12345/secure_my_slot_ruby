class Account::BookingHistoryController < Account::BaseController
  PER_PAGE = 5

  STATUS_OPTIONS = %w[Completed Cancelled Pending].freeze
  DATE_RANGE_OPTIONS = ["Last 30 days", "Last 3 months", "Last 6 months", "This year"].freeze

  def index
    past_scope = current_user.bookings
                             .where(
                               "date < :today OR (date = :today AND time < :current_time)",
                               today: Date.current,
                               current_time: Time.current
                             )

    # --- Stats are always based on the FULL history, unaffected by filters ---
    @total_bookings = past_scope.count

    @bookings_completed = past_scope.where(status: "completed").count
    @bookings_canceled  = past_scope.where(status: "cancelled").count

    @completion_rate =
      if @total_bookings.positive?
        ((@bookings_completed.to_f / @total_bookings) * 100).round
      else
        0
      end

    @total_spent = past_scope
                     .joins(:service)
                     .where(status: "completed")
                     .sum("services.price")

    @first_booking = past_scope.reorder(date: :asc, time: :asc).first

    # --- Filters (only affect the table below) ---
    @query      = params[:query].to_s.strip
    @status     = params[:status].presence
    @date_range = params[:date_range].presence

    filtered_scope = past_scope.order(date: :desc, time: :desc)

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
        when "Last 30 days"  then 30.days.ago.to_date
        when "Last 3 months" then 3.months.ago.to_date
        when "Last 6 months" then 6.months.ago.to_date
        when "This year"     then Date.current.beginning_of_year
        end

      filtered_scope = filtered_scope.where("date >= ?", from_date)
    end

    @total_past_bookings = filtered_scope.count

    # --- Pagination (based on the filtered scope) ---
    @per_page   = PER_PAGE
    @total_pages = [(@total_past_bookings.to_f / @per_page).ceil, 1].max

    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page = @total_pages if @page > @total_pages

    @booking_history = filtered_scope
                         .limit(@per_page)
                         .offset((@page - 1) * @per_page)
  end
end