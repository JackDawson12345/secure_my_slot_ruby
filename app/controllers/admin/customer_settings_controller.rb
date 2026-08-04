class Admin::CustomerSettingsController < Admin::BaseController
  before_action :set_customer
  before_action :set_business
  before_action :set_settings

  def edit
  end

  def update
    BusinessSetting.transaction do
      @settings.update!(settings_params)

      @business.update!(
        business_update_params
      )
    end

    redirect_to admin_customer_path(
                  @customer,
                  tab: "settings"
                ),
                notice: "Business settings were updated successfully."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  private

  def set_customer
    @customer = User
                  .where(role: 1)
                  .find(params[:customer_id])
  end

  def set_business
    @business = @customer.business

    return if @business.present?

    redirect_to admin_customer_path(@customer),
                alert: "This customer does not have a business profile."
  end

  def set_settings
    @settings = @business.business_setting ||
                @business.build_business_setting
  end

  def settings_params
    params.require(:business_setting).permit(
      :business_name,
      :business_category,
      :phone_number,
      :business_email,
      :business_description,
      :address_line_1,
      :address_line_2,
      :town_or_city,
      :postcode,
      :country,
      :booking_page_live,
      :automatically_confirm_bookings,
      :allow_customer_cancellations,
      :require_customer_phone_number,
      :cancellation_notice_hours,
      :new_booking_notifications,
      :cancellation_notifications,
      :daily_appointment_summary
    )
  end

  def business_update_params
    attributes = business_params.to_h

    if settings_params[:business_name].present?
      attributes["business_name"] =
        settings_params[:business_name]
    end

    attributes
  end

  def business_params
    params.fetch(:business, {}).permit(
      :subscribed
    )
  end
end