class BusinessAgent::DashboardController < BusinessAgent::BaseController
  def index
    @business_agent = BusinessAgent.find_by!(user_id: current_user.id)
    @business = @business_agent.business

    bookings = @business.bookings
                        .where(agent_id: @business_agent.id)

    today = Date.current

    @today_bookings = bookings
                        .where(date: today)
                        .where.not(status: %w[cancelled canceled])
                        .order(:time)

    @today_bookings_count = @today_bookings.count

    @this_week_bookings_count = bookings
                                  .where(date: today.beginning_of_week..today.end_of_week)
                                  .where.not(status: %w[cancelled canceled])
                                  .count

    @completed_bookings_count = bookings
                                  .where(status: "completed")
                                  .where(date: today.beginning_of_month..today.end_of_month)
                                  .count

    @upcoming_bookings_count = bookings
                                 .where(date: today..)
                                 .where.not(status: %w[cancelled canceled completed])
                                 .count

    @next_booking = @today_bookings
                      .where("time >= ?", Time.current)
                      .first
  end
end
