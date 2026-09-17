require "csv"

class BusinessPortal::CustomersController < BusinessPortal::BaseController
  def index
    @business = current_user.business

    @bookings = Booking
                  .where(business: @business)
                  .where.not(user_id: nil)
                  .includes(:user, :service)
                  .order(date: :desc, time: :desc)

    # ----------------------------------------
    # Build complete customer collection
    # ----------------------------------------

    all_customers = @bookings
                      .group_by(&:user)
                      .map do |user, bookings|

      sorted_bookings = bookings.sort_by do |booking|
        [booking.date, booking.time]
      end

      first_booking = sorted_bookings.first
      last_booking = sorted_bookings.last

      total_spent = sorted_bookings
                      .select { |booking| booking.status == "confirmed" }
                      .sum { |booking| booking.service&.price.to_d }

      active = sorted_bookings.any? do |booking|
        booking.date >= 90.days.ago.to_date
      end

      new_this_month =
        first_booking.present? &&
        first_booking.date >= Date.current.beginning_of_month &&
        first_booking.date <= Date.current.end_of_month

      repeat_customer = sorted_bookings.count > 1

      {
        user: user,
        bookings: sorted_bookings,
        total_bookings: sorted_bookings.count,
        first_booking: first_booking,
        last_booking: last_booking,
        total_spent: total_spent,
        active: active,
        new_this_month: new_this_month,
        repeat_customer: repeat_customer
      }
    end
                      .sort_by do |customer|
      [
        customer[:last_booking].date,
        customer[:last_booking].time
      ]
    end
                      .reverse

    # ----------------------------------------
    # Statistics
    # These use ALL customers, not filtered
    # ----------------------------------------

    @total_customers = all_customers.count

    @active_customers = all_customers.count do |customer|
      customer[:active]
    end

    @new_customers_this_month = all_customers.count do |customer|
      customer[:new_this_month]
    end

    @repeat_customers = all_customers.count do |customer|
      customer[:repeat_customer]
    end

    @repeat_customer_percentage =
      if @total_customers.positive?
        ((@repeat_customers.to_f / @total_customers) * 100).round
      else
        0
      end

    # ----------------------------------------
    # Start filtered collection
    # ----------------------------------------

    @customers = all_customers

    # ----------------------------------------
    # Search
    # Name, email and phone number
    # ----------------------------------------

    if params[:q].present?
      search = params[:q].to_s.strip.downcase

      @customers = @customers.select do |customer|
        user = customer[:user]

        first_name = user.respond_to?(:first_name) ? user.first_name.to_s : ""
        last_name = user.respond_to?(:last_name) ? user.last_name.to_s : ""
        email = user.email.to_s
        phone = user.respond_to?(:phone_number) ? user.phone_number.to_s : ""

        full_name = "#{first_name} #{last_name}"

        first_name.downcase.include?(search) ||
          last_name.downcase.include?(search) ||
          full_name.downcase.include?(search) ||
          email.downcase.include?(search) ||
          phone.downcase.include?(search)
      end
    end

    # ----------------------------------------
    # Status filter
    # ----------------------------------------

    case params[:status]
    when "active"
      @customers = @customers.select do |customer|
        customer[:active]
      end

    when "inactive"
      @customers = @customers.reject do |customer|
        customer[:active]
      end
    end

    # ----------------------------------------
    # Customer type filter
    # ----------------------------------------

    case params[:customer_type]
    when "new"
      @customers = @customers.select do |customer|
        customer[:new_this_month]
      end

    when "repeat"
      @customers = @customers.select do |customer|
        customer[:repeat_customer]
      end

    when "single"
      @customers = @customers.select do |customer|
        customer[:total_bookings] == 1
      end
    end

    # ----------------------------------------
    # CSV export
    # Exports filtered results
    # ----------------------------------------

    respond_to do |format|
      format.html

      format.csv do
        send_data(
          customers_csv(@customers),
          filename: "customers-#{Date.current}.csv",
          type: "text/csv; charset=utf-8",
          disposition: "attachment"
        )
      end
    end
  end

  def show
    customer = current_user.business.bookings
                           .where(user_id: params[:id])
                           .first
                 &.user

    unless customer
      redirect_to business_portal_customers_path, alert: "Customer not found"
      return
    end

    @customer = customer
  end

  private

  def customers_csv(customers)
    CSV.generate(headers: true) do |csv|
      csv << [
        "First Name",
        "Last Name",
        "Email",
        "Phone Number",
        "Total Bookings",
        "First Booking",
        "Last Booking",
        "Last Service",
        "Total Spent",
        "Status",
        "Customer Type"
      ]

      customers.each do |customer|
        user = customer[:user]
        first_booking = customer[:first_booking]
        last_booking = customer[:last_booking]

        csv << [
          user.respond_to?(:first_name) ? user.first_name : nil,
          user.respond_to?(:last_name) ? user.last_name : nil,
          user.email,
          user.respond_to?(:phone_number) ? user.phone_number : nil,
          customer[:total_bookings],
          first_booking&.date&.strftime("%d/%m/%Y"),
          last_booking&.date&.strftime("%d/%m/%Y"),
          last_booking&.service&.name,
          format("%.2f", customer[:total_spent]),
          customer[:active] ? "Active" : "Inactive",
          customer_type_label(customer)
        ]
      end
    end
  end

  def customer_type_label(customer)
    if customer[:new_this_month]
      "New"
    elsif customer[:repeat_customer]
      "Repeat"
    else
      "Single Booking"
    end
  end
end