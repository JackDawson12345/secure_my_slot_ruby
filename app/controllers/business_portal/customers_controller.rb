class BusinessPortal::CustomersController < BusinessPortal::BaseController
  def index
    @bookings = Booking
                  .where(business: current_user.business)
                  .where.not(user_id: nil)
                  .includes(:user, :service)
                  .order(date: :desc, time: :desc)

    @customers = @bookings
                   .group_by(&:user)
                   .map do |user, bookings|
      sorted_bookings = bookings.sort_by do |booking|
        [booking.date, booking.time]
      end

      first_booking = sorted_bookings.first
      last_booking = sorted_bookings.last

      {
        user: user,
        bookings: sorted_bookings,
        total_bookings: sorted_bookings.count,
        first_booking: first_booking,
        last_booking: last_booking,
        total_spent: sorted_bookings
                       .select { |booking| booking.status == "confirmed" }
                       .sum { |booking| booking.service&.price.to_d },
        active: sorted_bookings.any? do |booking|
          booking.date >= 90.days.ago.to_date
        end
      }
    end
                   .sort_by do |customer|
      [
        customer[:last_booking].date,
        customer[:last_booking].time
      ]
    end
                   .reverse

    @total_customers = @customers.count

    @active_customers = @customers.count do |customer|
      customer[:active]
    end

    @new_customers_this_month = @customers.count do |customer|
      first_booking = customer[:first_booking]

      first_booking.present? &&
        first_booking.date >= Date.current.beginning_of_month &&
        first_booking.date <= Date.current.end_of_month
    end

    @repeat_customers = @customers.count do |customer|
      customer[:total_bookings] > 1
    end

    @repeat_customer_percentage =
      if @total_customers.positive?
        ((@repeat_customers.to_f / @total_customers) * 100).round
      else
        0
      end
  end
end