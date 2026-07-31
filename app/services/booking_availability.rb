class BookingAvailability

  def initialize(business, service, date)
    @business = business
    @service = service
    @date = date
  end


  def call

    opening_hour = @business.opening_hours.find_by(
      day_of_week: @date.strftime("%A").downcase
    )

    return [] unless opening_hour&.open


    settings = @business.booking_setting


    slots = []


    current = Time.zone.parse(
      "#{@date} #{opening_hour.opens_at.strftime('%H:%M')}"
    )


    finish = Time.zone.parse(
      "#{@date} #{opening_hour.closes_at.strftime('%H:%M')}"
    )


    # Apply minimum notice time
    if @date == Date.current

      earliest_booking_time =
        Time.current + settings.minimum_notice_minutes.minutes


      if earliest_booking_time > current

        current = round_to_interval(
          earliest_booking_time,
          settings.booking_interval_minutes
        )

      end

    end



    while current + @service.minutes_duration.minutes <= finish

      unless booked?(current)
        slots << current.strftime("%H:%M")
      end


      current += settings.booking_interval_minutes.minutes

    end


    slots

  end



  private



  def round_to_interval(time, interval)

    seconds = interval.minutes

    Time.at(
      (time.to_f / seconds).ceil * seconds
    ).in_time_zone

  end



  def booked?(time)

    start_time = time

    end_time =
      time +
      @service.minutes_duration.minutes



    @business.bookings
             .where(date: @date)
             .where.not(status: "cancelled")
             .any? do |booking|


      booking_start =
        Time.zone.parse(
          "#{@date} #{booking.time.strftime('%H:%M')}"
        )


      booking_end =
        booking_start +
        booking.service.minutes_duration.minutes


      start_time < booking_end &&
        end_time > booking_start

    end

  end

end