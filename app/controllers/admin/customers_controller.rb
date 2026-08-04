class Admin::CustomersController < Admin::BaseController
  TABS = %w[
    overview
    bookings
    customers
    services
    opening_hours
    website_settings
    settings
  ].freeze

  def index
    customer_scope = User
                       .where(role: 1)
                       .left_joins(business: :business_setting)
                       .includes(
                         business: [
                           :business_setting,
                           :services,
                           :bookings
                         ]
                       )
                       .distinct

    @total_customers = User.where(role: 1).count

    @new_customers_this_month = User
                                  .where(role: 1)
                                  .where(created_at: Time.current.beginning_of_month..)
                                  .count

    @active_customers = User
                          .where(role: 1)
                          .joins(business: :business_setting)
                          .where(
                            business_settings: {
                              booking_page_live: true
                            }
                          )
                          .distinct
                          .count

    @total_bookings = Booking
                        .joins(business: :user)
                        .where(users: { role: 1 })
                        .count

    if params[:query].present?
      search_term = ActiveRecord::Base.sanitize_sql_like(
        params[:query].strip
      )

      customer_scope = customer_scope.where(
        <<~SQL.squish,
          users.first_name ILIKE :query
          OR users.last_name ILIKE :query
          OR users.email ILIKE :query
          OR users.phone_number ILIKE :query
          OR businesses.business_name ILIKE :query
          OR businesses.page_address ILIKE :query
        SQL
        query: "%#{search_term}%"
      )
    end

    case params[:status]
    when "live"
      customer_scope = customer_scope.where(
        business_settings: {
          booking_page_live: true
        }
      )
    when "offline"
      customer_scope = customer_scope.where(
        "business_settings.booking_page_live = ? " \
          "OR business_settings.booking_page_live IS NULL",
        false
      )
    end

    @customers = customer_scope.order(created_at: :desc)
  end

  def show
    @customer = User
                  .where(role: 1)
                  .includes(
                    business: [
                      :business_setting,
                      :business_website,
                      :opening_hours,
                      :services,
                      {
                        bookings: [
                          :service,
                          :user
                        ]
                      }
                    ]
                  )
                  .find(params[:id])

    @business = @customer.business
    @active_tab = permitted_tab

    return unless @business

    @bookings = @business.bookings
                         .includes(:service, :user)
                         .order(date: :desc, time: :desc)

    @services = @business.services.order(:name)

    @opening_hours = @business.opening_hours

    @booking_customers = User
                           .joins(:bookings)
                           .where(bookings: { business_id: @business.id })
                           .distinct
                           .order(:first_name, :last_name, :email)

    @total_bookings = @bookings.size
    @total_services = @services.size
    @total_booking_customers = @booking_customers.size

    @upcoming_bookings = @bookings.select do |booking|
      booking_starts_at(booking)&.future?
    end

    @completed_bookings = @bookings.select do |booking|
      booking_starts_at(booking)&.past?
    end
  end

  private

  def permitted_tab
    params[:tab].presence_in(TABS) || "overview"
  end

  def booking_starts_at(booking)
    return if booking.date.blank? || booking.time.blank?

    Time.zone.parse(
      "#{booking.date} #{booking.time.strftime('%H:%M')}"
    )
  end
end