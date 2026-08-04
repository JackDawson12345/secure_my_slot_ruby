class BusinessPortal::BlockedTimesController <
  BusinessPortal::BaseController

  before_action :set_business
  before_action :set_blocked_time, only: [:edit, :update, :destroy]

  def index
    prepare_index
  end

  def create
    @blocked_time =
      @business.business_blocked_times.new(blocked_time_params)

    normalise_blocked_time(@blocked_time)

    if @blocked_time.save
      redirect_to business_blocked_times_path,
                  notice: "Blocked time added successfully."
    else
      prepare_index(load_new_record: false)

      flash.now[:alert] = "Please correct the errors below."
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @blocked_time.assign_attributes(blocked_time_params)
    normalise_blocked_time(@blocked_time)

    if @blocked_time.save
      redirect_to business_blocked_times_path,
                  notice: "Blocked time updated successfully."
    else
      flash.now[:alert] = "Please correct the errors below."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blocked_time.destroy!

    redirect_to business_blocked_times_path,
                notice: "Blocked time removed successfully."
  end

  private

  def set_business
    @business = current_user.business
  end

  def set_blocked_time
    @blocked_time =
      @business.business_blocked_times.find(params[:id])
  end

  def prepare_index(load_new_record: true)
    @blocked_time =
      @business.business_blocked_times.new if load_new_record

    @upcoming_blocked_times =
      @business.business_blocked_times.upcoming

    @past_blocked_times =
      @business.business_blocked_times.past.limit(10)
  end

  def blocked_time_params
    params.require(:business_blocked_time).permit(
      :title,
      :date,
      :end_date,
      :start_time,
      :end_time,
      :all_day,
      :notes
    )
  end

  def normalise_blocked_time(blocked_time)
    start_date = parse_date(
      params.dig(:business_blocked_time, :date)
    )

    end_date = parse_date(
                 params.dig(:business_blocked_time, :end_date)
               ) || start_date

    return if start_date.blank?

    all_day = ActiveModel::Type::Boolean.new.cast(
      params.dig(:business_blocked_time, :all_day)
    )

    if all_day
      blocked_time.starts_at =
        Time.zone.local(
          start_date.year,
          start_date.month,
          start_date.day
        ).beginning_of_day

      blocked_time.ends_at =
        Time.zone.local(
          end_date.year,
          end_date.month,
          end_date.day
        ).end_of_day
    else
      blocked_time.starts_at = combine_date_and_time(
        start_date,
        params.dig(:business_blocked_time, :start_time)
      )

      blocked_time.ends_at = combine_date_and_time(
        end_date,
        params.dig(:business_blocked_time, :end_time)
      )
    end
  end

  def parse_date(value)
    return if value.blank?

    Date.iso8601(value)
  rescue Date::Error
    nil
  end

  def combine_date_and_time(date, time_value)
    return if date.blank? || time_value.blank?

    parsed_time = Time.zone.parse(time_value)
    return if parsed_time.blank?

    Time.zone.local(
      date.year,
      date.month,
      date.day,
      parsed_time.hour,
      parsed_time.min
    )
  end
end