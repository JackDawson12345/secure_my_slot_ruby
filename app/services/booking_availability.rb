class BookingAvailability
  def initialize(business, service, date)
    @business = business
    @service = service
    @date = date.to_date
  end

  def call
    return [] unless valid_booking_date?

    opening_hour = @business.opening_hours.find_by(
      day_of_week: @date.strftime("%A").downcase
    )

    return [] unless opening_hour&.open?

    current = time_on_date(opening_hour.opens_at)
    finish = time_on_date(opening_hour.closes_at)

    earliest_booking_time = Time.current + minimum_notice_minutes.minutes

    if earliest_booking_time > current
      current = round_to_interval(
        earliest_booking_time,
        booking_interval_minutes
      )
    end

    slots = []

    while current + service_duration.minutes <= finish
      slot_end = current + service_duration.minutes

      slots << current.strftime("%H:%M") unless unavailable?(
        current,
        slot_end
      )

      current += booking_interval_minutes.minutes
    end

    slots
  end

  private

  def settings
    @settings ||= @business.booking_setting
  end

  def valid_booking_date?
    return false unless settings
    return false if @date < Date.current

    @date <= Date.current + advance_booking_days.days
  end

  def booking_interval_minutes
    settings.booking_interval_minutes.to_i
  end

  def minimum_notice_minutes
    settings.minimum_notice_minutes.to_i
  end

  def advance_booking_days
    settings.advance_booking_days.to_i
  end

  def buffer_minutes
    settings.buffer_minutes.to_i
  end

  def service_duration
    @service.minutes_duration.to_i
  end

  def time_on_date(time)
    Time.zone.local(
      @date.year,
      @date.month,
      @date.day,
      time.hour,
      time.min
    )
  end

  def round_to_interval(time, interval)
    raise ArgumentError, "Booking interval must be greater than zero" if interval <= 0

    interval_seconds = interval.minutes

    Time.at(
      (time.to_f / interval_seconds).ceil * interval_seconds
    ).in_time_zone
  end

  def unavailable?(start_time, end_time)
    booked?(start_time, end_time) ||
      blocked?(start_time, end_time)
  end

  def booked?(start_time, end_time)
    proposed_end_with_buffer =
      end_time + buffer_minutes.minutes

    bookings_for_date.any? do |booking|
      booking_start = time_on_date(booking.time)

      booking_end_with_buffer =
        booking_start +
        booking.service.minutes_duration.minutes +
        buffer_minutes.minutes

      overlaps?(
        start_time,
        proposed_end_with_buffer,
        booking_start,
        booking_end_with_buffer
      )
    end
  end

  def blocked?(start_time, end_time)
    blocked_times_for_date.any? do |blocked_time|
      overlaps?(
        start_time,
        end_time,
        blocked_time.starts_at,
        blocked_time.ends_at
      )
    end
  end

  def bookings_for_date
    @bookings_for_date ||= @business.bookings
                                    .includes(:service)
                                    .where(date: @date)
                                    .where.not(status: "cancelled")
                                    .to_a
  end

  def blocked_times_for_date
    @blocked_times_for_date ||= @business.business_blocked_times
                                         .where(
                                           "starts_at < ? AND ends_at > ?",
                                           day_end,
                                           day_start
                                         )
                                         .to_a
  end

  def overlaps?(
    first_start,
    first_end,
    second_start,
    second_end
  )
    first_start < second_end &&
      first_end > second_start
  end

  def day_start
    @day_start ||= @date.in_time_zone.beginning_of_day
  end

  def day_end
    @day_end ||= @date.in_time_zone.end_of_day
  end
end