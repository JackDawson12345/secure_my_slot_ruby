class Account::BookAppointmentController < Account::BaseController
  DISTANCE_STEPS = [5, 10, 25, 50, 100, nil].freeze # nil = Unlimited
  PER_PAGE = 10

  def index
    businesses = Business.includes(:business_setting, :opening_hours, services: {})
    businesses = filter_by_category(businesses).to_a
    businesses = filter_by_distance(businesses)

    @next_slots = businesses.each_with_object({}) do |business, memo|
      memo[business.id] = BusinessNextAvailableSlot.new(business).call
    end

    businesses = filter_by_availability(businesses)

    @total_count = businesses.size
    @total_pages = [(@total_count.to_f / PER_PAGE).ceil, 1].max

    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page = @total_pages if @page > @total_pages

    offset = (@page - 1) * PER_PAGE
    @businesses = businesses[offset, PER_PAGE] || []
  end

  private

  def selected_categories
    Array(params[:category]).reject(&:blank?)
  end

  def filter_by_category(businesses)
    return businesses if selected_categories.empty?

    businesses.joins(:business_setting)
              .where(business_settings: { business_category: selected_categories })
  end

  def filter_by_distance(businesses)
    return businesses if params[:distance].blank?

    max_miles = DISTANCE_STEPS[params[:distance].to_i]
    return businesses if max_miles.nil? # Unlimited

    businesses.select do |business|
      distance = business.distance_to_customer(current_user)
      distance.present? && distance <= max_miles
    end
  end

  def filter_by_availability(businesses)
    return businesses unless params[:available_today].present? || params[:available_this_week].present?

    # "Today" is the stricter of the two, so if both are somehow checked,
    # today wins.
    deadline = params[:available_today].present? ? Date.current : Date.current.end_of_week

    businesses.select do |business|
      next_slot = @next_slots[business.id]
      next_slot.present? && next_slot[:date] <= deadline
    end
  end
end