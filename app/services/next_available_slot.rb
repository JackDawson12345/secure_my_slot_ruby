class NextAvailableSlot
  MAX_DAYS_TO_SEARCH = 90

  def initialize(business, service, start_date: Date.current)
    @business = business
    @service = service
    @start_date = start_date
  end

  def call
    (0...MAX_DAYS_TO_SEARCH).each do |offset|
      date = @start_date + offset.days
      slots = BookingAvailability.new(@business, @service, date).call

      return { date: date, time: slots.first } if slots.any?
    end

    nil
  end
end