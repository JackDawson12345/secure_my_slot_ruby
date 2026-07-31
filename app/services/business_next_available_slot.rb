class BusinessNextAvailableSlot
  MAX_DAYS_TO_SEARCH = 90

  def initialize(business, start_time: Time.current)
    @business = business
    @start_time = start_time
  end

  def call

    @business.services.filter_map do |service|
      result = NextAvailableSlot.new(
        @business,
        service,
        start_date: @start_time.to_date
      ).call

      result&.merge(service: service)
    end.min_by { |r| [r[:date], r[:time]] }
  end
end