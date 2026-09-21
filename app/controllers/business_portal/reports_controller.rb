class BusinessPortal::ReportsController < BusinessPortal::BaseController
  def index
    @bookings = Booking.where(business_id: current_user.id)

    @total_amount = @bookings.sum(:amount)

    @users = User.where(id: @bookings.pluck(:user_id).uniq)

    @page_views = current_user.business.page_views.count

    @conversion_rate = if @page_views.positive?
                         (@bookings.count.to_f / @page_views.to_f) * 100
                       else
                         0
                       end
  end

  def booking

    @bookings = Booking.where(business_id: current_user.id)

    @bookings_pending = @bookings.where(status: 'pending')
    @bookings_confirmed = @bookings.where(status: 'confirmed')
    @bookings_completed = @bookings.where(status: 'completed')
    @bookings_cancelled = @bookings.where(status: 'cancelled')

    # Bookings by day
    days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

    booking_counts = @bookings.group_by do |booking|
      booking.date.strftime("%A")
    end.transform_values(&:count)

    @bookings_by_day = days.map do |day|
      booking_counts[day] || 0
    end


    # Busy periods heat map
    heatmap_hours = [
      9,
      11,
      13,
      15,
      17,
      19
    ]

    @booking_heatmap = days.map do |day|

      @bookings_for_day = @bookings.select do |booking|
        booking.date.strftime("%A") == day
      end

      heatmap_hours.map do |hour|

        @bookings_for_day.count do |booking|
          booking.time.hour.between?(hour, hour + 1)
        end

      end

    end

    service_counts = @bookings
                       .group(:service_id)
                       .count
                       .sort_by { |_service_id, count| -count }


    services = Service.where(id: service_counts.map(&:first)).index_by(&:id)


    total_bookings = service_counts.sum { |_service_id, count| count }


    @popular_services = service_counts.map do |service_id, count|

      {
        name: services[service_id].name,
        count: count,
        percentage: ((count.to_f / total_bookings) * 100).round
      }

    end

  end

  def revenue

  end

  def customer
    @bookings = Booking.where(business_id: current_user.business.id)

    @users = User.where(
      id: @bookings.select(:user_id).distinct
    )

    booking_counts = @bookings.group(:user_id).count

    @new_customers =
      booking_counts.count { |_user_id, count| count == 1 }

    @returning_customers =
      booking_counts.count { |_user_id, count| count > 1 }

    @total_customers = @new_customers + @returning_customers

    @new_customer_percentage =
      if @total_customers.positive?
        ((@new_customers.to_f / @total_customers) * 100).round(1)
      else
        0
      end

    @returning_customer_percentage =
      if @total_customers.positive?
        ((@returning_customers.to_f / @total_customers) * 100).round(1)
      else
        0
      end

    @page_views = current_user.business.page_views

    business_created_at = current_user.business.created_at

    months_active =
      ((Time.current.year * 12 + Time.current.month) -
        (business_created_at.year * 12 + business_created_at.month)) + 1

    @average_page_views_per_month =
      (@page_views.count.to_f / months_active).round(1)

    @top_customers = @users
                       .joins(:bookings)
                       .where(bookings: { business_id: current_user.business.id })
                       .group("users.id")
                       .order(Arel.sql("COUNT(bookings.id) DESC"))
                       .limit(5)
                       .select("users.*, COUNT(bookings.id) AS bookings_count")

    six_months_ago = 5.months.ago.beginning_of_month

    first_bookings = @bookings
                       .group(:user_id)
                       .minimum(:created_at)

    @customer_growth_labels = []
    @customer_growth_data = []

    6.times do |i|
      month = six_months_ago + i.months

      @customer_growth_labels << month.strftime("%b")

      @customer_growth_data << first_bookings.count do |_user_id, first_booking_date|
        first_booking_date >= month.beginning_of_month &&
          first_booking_date <= month.end_of_month
      end
    end
  end

  def service
    @bookings = current_user.business.bookings
    @services = current_user.business.services

    # Booking count per service
    @service_booking_counts = @bookings
                                .group(:service_id)
                                .count

    # Most booked service
    most_booked_service_id = @service_booking_counts
                               .max_by { |_service_id, count| count }
                               &.first

    @most_booked_service = @services.find_by(id: most_booked_service_id)

    # Average service cost
    @average_service_cost = @services.average(:price)&.round(2) || 0

    # Average service duration
    @average_service_duration = @services.average(:minutes_duration)&.round || 0

    # Chart data
    @service_booking_labels = @services.map(&:name)

    @service_booking_data = @services.map do |service|
      @service_booking_counts.fetch(service.id, 0)
    end

    # Revenue grouped by service
    @service_revenue_totals = @bookings
                                .group(:service_id)
                                .sum(:amount)

    @service_revenue = @services.map do |service|
      {
        service: service,
        booking_count: @service_booking_counts.fetch(service.id, 0),
        revenue: @service_revenue_totals.fetch(service.id, 0)
      }
    end.sort_by { |item| -item[:revenue] }

    # Highest revenue for progress bar calculation
    max_revenue = @service_revenue.map { |item| item[:revenue] }.max || 0

    @service_revenue.each do |item|
      item[:percentage] =
        if max_revenue.positive?
          ((item[:revenue] / max_revenue) * 100).round
        else
          0
        end
    end

  end

  def staff

  end

  def website
    @business = current_user.business
    @page_views = @business.page_views
    @bookings = @business.bookings

    # --------------------------------
    # Website overview
    # --------------------------------

    @total_page_views = @page_views.count

    @unique_visitors =
      @page_views
        .where.not(visitor_id: [nil, ""])
        .distinct
        .count(:visitor_id)

    @booking_count = @bookings.count

    @booking_conversion = if @page_views.count.positive?
                         (@bookings.count.to_f / @page_views.count.to_f) * 100
                       else
                         0
                       end

    @views_per_visitor =
      if @unique_visitors.positive?
        (@total_page_views.to_f / @unique_visitors).round(1)
      else
        0
      end


    # --------------------------------
    # Website traffic: last 6 months
    # --------------------------------

    @traffic_months =
      (0..5)
        .map { |i| i.months.ago.beginning_of_month }
        .reverse

    @traffic_labels =
      @traffic_months.map { |month| month.strftime("%b") }

    @traffic_data =
      @traffic_months.map do |month|
        @page_views
          .where(created_at: month.beginning_of_month..month.end_of_month)
          .where.not(visitor_id: [nil, ""])
          .distinct
          .count(:visitor_id)
      end


    # --------------------------------
    # Traffic sources
    # --------------------------------

    @traffic_sources =
      @page_views
        .where.not(traffic_source: [nil, ""])
        .group(:traffic_source)
        .count

    @google_visits = @traffic_sources["google"].to_i
    @direct_visits = @traffic_sources["direct"].to_i
    @social_visits = @traffic_sources["social"].to_i
    @referral_visits = @traffic_sources["referral"].to_i
    @other_visits = @traffic_sources["other"].to_i

    @tracked_source_views =
      @traffic_sources.values.sum

    @google_percentage =
      percentage(@google_visits, @tracked_source_views)

    @direct_percentage =
      percentage(@direct_visits, @tracked_source_views)

    @social_percentage =
      percentage(@social_visits, @tracked_source_views)

    @referral_percentage =
      percentage(@referral_visits, @tracked_source_views)


    # --------------------------------
    # Device breakdown
    # --------------------------------

    @device_counts =
      @page_views
        .where.not(device_type: [nil, ""])
        .group(:device_type)
        .count

    @mobile_views = @device_counts["mobile"].to_i
    @desktop_views = @device_counts["desktop"].to_i
    @tablet_views = @device_counts["tablet"].to_i

    @tracked_device_views =
      @device_counts.values.sum

    @mobile_percentage =
      percentage(@mobile_views, @tracked_device_views)

    @desktop_percentage =
      percentage(@desktop_views, @tracked_device_views)

    @tablet_percentage =
      percentage(@tablet_views, @tracked_device_views)


    # --------------------------------
    # Visitor activity
    # --------------------------------

    visitor_counts =
      @page_views
        .where.not(visitor_id: [nil, ""])
        .group(:visitor_id)
        .count

    @new_visitors =
      visitor_counts.count { |_visitor_id, count| count == 1 }

    @returning_visitors =
      visitor_counts.count { |_visitor_id, count| count > 1 }

    @new_visitor_percentage =
      percentage(@new_visitors, @unique_visitors)

    @returning_visitor_percentage =
      percentage(@returning_visitors, @unique_visitors)
  end

  private

  def percentage(value, total)
    return 0 if total.zero?

    ((value.to_f / total) * 100).round(1)
  end
end
