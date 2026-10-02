# app/controllers/business_agent/opening_hours_controller.rb

class BusinessAgent::OpeningHoursController < BusinessAgent::BaseController

  def index
    @opening_hours = @business.opening_hours
                              .includes(:breaks)
                              .sort_by(&:day_of_week_before_type_cast)

    @booking_setting = @business.booking_setting
  end
end

