# app/controllers/admin/dashboard_controller.rb

class Admin::DashboardController < Admin::BaseController
  def index
    load_summary_metrics
    load_booking_metrics
    load_recent_records
  end

  private

  def load_summary_metrics
    @businesses_count = Business.count
    @customers_count = User.where(role: :customer).count
    @business_users_count = User.where(role: :business).count
    @services_count = Service.count

    @live_booking_pages_count = BusinessSetting.where(
      booking_page_live: true
    ).count
  end

  def load_booking_metrics
    @bookings_count = Booking.count

    @today_bookings = Booking
                        .includes(:business, :service, :user)
                        .where(date: Date.current)
                        .order(:time)

    @today_bookings_count = @today_bookings.size

    @upcoming_bookings_count = Booking
                                 .where(date: Date.current..30.days.from_now.to_date)
                                 .count

    @bookings_this_month = Booking
                             .where(date: Date.current.beginning_of_month..Date.current.end_of_month)
                             .count

    previous_month = 1.month.ago.to_date

    @bookings_last_month = Booking
                             .where(
                               date: previous_month.beginning_of_month..
                                 previous_month.end_of_month
                             )
                             .count

    @monthly_booking_change = percentage_change(
      current: @bookings_this_month,
      previous: @bookings_last_month
    )
  end

  def load_recent_records
    @recent_bookings = Booking
                         .includes(:business, :service, :user)
                         .order(created_at: :desc)
                         .limit(6)

    @recent_businesses = Business
                           .includes(:user, :business_setting)
                           .order(created_at: :desc)
                           .limit(5)

    @recent_customers = User
                          .where(role: :customer)
                          .order(created_at: :desc)
                          .limit(5)
  end

  def percentage_change(current:, previous:)
    return 0 if current.zero? && previous.zero?
    return 100 if previous.zero?

    (((current - previous).to_f / previous) * 100).round
  end
end