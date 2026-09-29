class Account::BookAppointmentController < Account::BaseController
  DISTANCE_STEPS = [5, 10, 25, 50, 100, nil].freeze # nil = Unlimited
  PER_PAGE = 10

  def index
    businesses = Business.includes(
      :business_setting,
      :opening_hours,
      :services
    )

    businesses = filter_by_search(businesses)
    businesses = filter_by_location(businesses)
    businesses = filter_by_category(businesses)

    businesses = businesses.to_a

    @distances = businesses.each_with_object({}) do |business, memo|
      memo[business.id] = business.distance_to_customer(current_user)
    end

    businesses = filter_by_distance(businesses)

    @next_slots = businesses.each_with_object({}) do |business, memo|
      memo[business.id] = BusinessNextAvailableSlot.new(business).call
    end

    businesses = filter_by_availability(businesses)
    businesses = sort_businesses(businesses)

    @total_count = businesses.size
    @total_pages = [(@total_count.to_f / PER_PAGE).ceil, 1].max

    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page = @total_pages if @page > @total_pages

    offset = (@page - 1) * PER_PAGE

    @businesses = businesses[offset, PER_PAGE] || []
  end


  private


  def filter_by_search(businesses)
    return businesses if params[:search].blank?

    search_term = "%#{params[:search].downcase}%"

    businesses
      .joins(:business_setting, :services)
      .where(
        "
        LOWER(businesses.business_name) LIKE :term
        OR LOWER(business_settings.business_category) LIKE :term
        OR LOWER(services.name) LIKE :term
        OR LOWER(services.description) LIKE :term
        ",
        term: search_term
      )
      .distinct
  end


  def filter_by_location(businesses)
    return businesses if params[:location].blank?

    location = "%#{params[:location].downcase}%"

    businesses
      .joins(:business_setting)
      .where(
        "
        LOWER(business_settings.address_line_1) LIKE :location
        OR LOWER(business_settings.address_line_2) LIKE :location
        OR LOWER(business_settings.town_or_city) LIKE :location
        OR LOWER(business_settings.postcode) LIKE :location
        OR LOWER(business_settings.country) LIKE :location
        ",
        location: location
      )
      .distinct
  end


  def selected_categories
    Array(params[:category]).reject(&:blank?)
  end


  def filter_by_category(businesses)
    return businesses if selected_categories.empty?

    businesses
      .joins(:business_setting)
      .where(
        business_settings: {
          business_category: selected_categories
        }
      )
  end


  def filter_by_distance(businesses)
    return businesses if params[:distance].blank?

    max_miles = DISTANCE_STEPS[params[:distance].to_i]

    return businesses if max_miles.nil?

    businesses.select do |business|
      distance = @distances[business.id]

      distance.present? &&
        distance <= max_miles
    end
  end


  def filter_by_availability(businesses)
    return businesses unless params[:available_today].present? ||
                             params[:available_this_week].present?

    deadline =
      if params[:available_today].present?
        Date.current
      else
        Date.current.end_of_week
      end

    businesses.select do |business|
      next_slot = @next_slots[business.id]

      next_slot.present? &&
        next_slot[:date] <= deadline
    end
  end


  def sort_businesses(businesses)
    businesses.sort_by do |business|
      subscription_priority =
        case business.subscription_level.to_s
        when "1", "2"
          0
        else
          1
        end

      secondary_sort =
        case params[:sort]
        when "distance"
          @distances[business.id] || Float::INFINITY

        when "soonest"
          next_slot = @next_slots[business.id]

          if next_slot
            Time.zone.parse(
              "#{next_slot[:date]} #{next_slot[:time]}"
            )
          else
            Time.zone.tomorrow
          end

        else
          0
        end

      [
        subscription_priority,
        secondary_sort
      ]
    end
  end
end