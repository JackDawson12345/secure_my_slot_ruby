class BusinessPortal::DashboardController < BusinessPortal::BaseController
  def index
    @business = current_user.business

    @bookings = Booking
                  .where(business: @business)
                  .where.not(user_id: nil)
                  .includes(:user, :service)

    set_today_bookings
    set_weekly_bookings
    set_customers
    set_monthly_revenue
  end

  private

  def set_today_bookings
    @today_bookings = @bookings
                        .where(date: Date.current)
                        .order(time: :asc)

    @today_bookings_count = @today_bookings.count

    yesterday_count = @bookings
                        .where(date: Date.current.yesterday)
                        .count

    @today_bookings_difference =
      @today_bookings_count - yesterday_count

    current_seconds = Time.current.seconds_since_midnight

    @next_booking = @today_bookings.find do |booking|
      booking.time.seconds_since_midnight >= current_seconds
    end
  end

  def set_weekly_bookings
    current_week_range =
      Date.current.beginning_of_week..Date.current.end_of_week

    previous_week_range =
      1.week.ago.to_date.beginning_of_week..
      1.week.ago.to_date.end_of_week

    @this_week_bookings_count = @bookings
                                  .where(date: current_week_range)
                                  .count

    previous_week_count = @bookings
                            .where(date: previous_week_range)
                            .count

    @weekly_percentage_change =
      percentage_change(
        @this_week_bookings_count,
        previous_week_count
      )
  end

  def set_customers
    customer_bookings = @bookings.group_by(&:user)

    @total_customers = customer_bookings.count

    @new_customers_this_month = customer_bookings.count do |_user, bookings|
      first_booking = bookings.min_by do |booking|
        [booking.date, booking.time]
      end

      first_booking.present? &&
        first_booking.date >= Date.current.beginning_of_month &&
        first_booking.date <= Date.current.end_of_month
    end
  end

  def set_monthly_revenue
    current_month_range =
      Date.current.beginning_of_month..Date.current.end_of_month

    previous_month_date = 1.month.ago.to_date

    previous_month_range =
      previous_month_date.beginning_of_month..
      previous_month_date.end_of_month

    @monthly_revenue = confirmed_revenue(current_month_range)

    previous_month_revenue =
      confirmed_revenue(previous_month_range)

    @monthly_revenue_percentage_change =
      percentage_change(
        @monthly_revenue,
        previous_month_revenue
      )
  end

  def confirmed_revenue(date_range)
    @bookings
      .where(date: date_range, status: "confirmed")
      .sum do |booking|
      booking.service&.price.to_d
    end
  end

  def percentage_change(current_value, previous_value)
    return 0 if previous_value.to_d.zero?

    (
      ((current_value.to_d - previous_value.to_d) /
        previous_value.to_d) * 100
    ).round
  end
end