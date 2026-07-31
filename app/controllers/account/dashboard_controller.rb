class Account::DashboardController < Account::BaseController
  RECENT_LIMIT   = 3
  UPCOMING_LIMIT = 3

  def index
    all_scope = current_user.bookings

    future_condition = [
      "date > :today OR (date = :today AND time >= :current_time)",
      { today: Date.current, current_time: Time.current }
    ]

    future_scope = all_scope.where(*future_condition)
    past_scope   = all_scope.where.not(*future_condition)

    # --- Summary cards ---
    @upcoming_count  = future_scope.where(status: %w[confirmed pending]).count
    @completed_count = all_scope.where(status: "completed").count

    @total_appointments = all_scope.count

    @most_booked_service =
      all_scope
        .joins(:service)
        .group("services.id", "services.name")
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(1)
        .count
        .first
        &.then { |(_ids, count)| count } # placeholder, replaced below

    # Cleaner version: get name + count together
    most_booked_row = all_scope
                        .joins(:service)
                        .group("services.id", "services.name")
                        .order(Arel.sql("COUNT(services.id) DESC"))
                        .limit(1)
                        .pluck("services.name", Arel.sql("COUNT(services.id)"))
                        .first

    @most_booked_service =
      if most_booked_row
        { name: most_booked_row[0], count: most_booked_row[1] }
      end

    @customer_since = current_user.created_at

    # --- Next appointment (nearest confirmed future booking) ---
    @next_booking = future_scope
                      .where(status: "confirmed")
                      .reorder(date: :asc, time: :asc)
                      .first

    # --- Upcoming appointments list (excludes the one already shown above) ---
    @upcoming_bookings = future_scope
                           .where(status: %w[confirmed pending])
                           .where.not(id: @next_booking&.id)
                           .order(date: :asc, time: :asc)
                           .limit(UPCOMING_LIMIT)

    # --- Recent bookings (latest completed appointments) ---
    @recent_bookings = past_scope
                         .where(status: "completed")
                         .order(date: :desc, time: :desc)
                         .limit(RECENT_LIMIT)

    # --- Business details panel ---
    # Assumption: show whichever business the next appointment belongs to;
    # if there's no upcoming booking, fall back to the most recent booking's
    # business. Adjust this if users only ever book with a single business.
    @primary_business =
      @next_booking&.business ||
      all_scope.order(date: :desc, time: :desc).first&.business

    # --- Reminder banner: only show if next appointment is within 48 hours ---
    @show_reminder = @next_booking.present? &&
                     @next_booking.date <= Date.current + 1.day
  end
end