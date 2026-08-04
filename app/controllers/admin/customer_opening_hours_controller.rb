# app/controllers/admin/customer_opening_hours_controller.rb

class Admin::CustomerOpeningHoursController < Admin::BaseController
  before_action :set_customer
  before_action :set_business

  def edit
    prepare_opening_hours
  end

  def update
    prepare_opening_hours

    if @business.update(opening_hours_params)
      redirect_to admin_customer_path(
                    @customer,
                    tab: "opening_hours"
                  ), notice: "Opening hours were updated successfully."
    else
      flash.now[:alert] =
        "Please check the opening hours and try again."

      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_customer
    @customer = User
                  .where(role: :business)
                  .find(params[:customer_id])
  end

  def set_business
    @business = @customer.business

    return if @business.present?

    redirect_to(
      admin_customer_path(@customer),
      alert: "This customer does not have a business profile."
    )
  end

  def prepare_opening_hours
    create_missing_weekdays

    @opening_hours = @business.opening_hours
                              .includes(:breaks)
                              .sort_by(&:day_of_week_before_type_cast)

    @booking_setting =
      @business.booking_setting ||
      @business.build_booking_setting(
        booking_interval_minutes: 30,
        minimum_notice_minutes: 240,
        advance_booking_days: 30,
        buffer_minutes: 0
      )
  end

  def create_missing_weekdays
    existing_days = @business.opening_hours.map(&:day_of_week)

    BusinessOpeningHour.day_of_weeks.each_key do |day|
      next if existing_days.include?(day)

      weekday = !%w[saturday sunday].include?(day)

      @business.opening_hours.create!(
        day_of_week: day,
        open: weekday,
        opens_at: weekday ? "09:00" : nil,
        closes_at: weekday ? "17:30" : nil
      )
    end
  end

  def opening_hours_params
    params.require(:business).permit(
      opening_hours_attributes: [
        :id,
        :day_of_week,
        :open,
        :opens_at,
        :closes_at,
        {
          breaks_attributes: [
            :id,
            :starts_at,
            :ends_at,
            :_destroy
          ]
        }
      ],
      booking_setting_attributes: [
        :id,
        :booking_interval_minutes,
        :minimum_notice_minutes,
        :advance_booking_days,
        :buffer_minutes
      ]
    )
  end
end