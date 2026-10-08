class NextAvailableSlot
  MAX_DAYS_TO_SEARCH = 90

  def initialize(
    business,
    service,
    agent: nil,
    start_date: Date.current
  )
    @business = business
    @service = service
    @agent = agent
    @start_date = start_date.to_date
  end

  def call
    (@start_date..(@start_date + MAX_DAYS_TO_SEARCH.days)).each do |date|
      slots = BookingAvailability.new(
        @business,
        @service,
        date,
        @agent
      ).call

      next if slots.empty?

      return {
        date: date,
        time: slots.first
      }
    end

    nil
  end
end