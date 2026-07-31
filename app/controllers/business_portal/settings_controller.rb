class BusinessPortal::SettingsController < BusinessPortal::BaseController
  before_action :set_business
  before_action :set_settings
  before_action :set_user

  def index
  end


  def update
    ActiveRecord::Base.transaction do

      @settings.update!(settings_params)

      @user.update!(user_params) if user_params.present?

    end

    redirect_to business_settings_path,
                notice: "Settings updated successfully."

  rescue ActiveRecord::RecordInvalid
    render :index, status: :unprocessable_entity
  end


  def update_password

    unless @user.valid_password?(params[:current_password])
      redirect_to business_settings_path,
                  alert: "Current password is incorrect."
      return
    end


    if params[:password] != params[:password_confirmation]

      redirect_to business_settings_path,
                  alert: "Passwords do not match."

      return
    end


    if @user.update(
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

      redirect_to business_settings_path,
                  notice: "Password updated successfully."

    else

      redirect_to business_settings_path,
                  alert: @user.errors.full_messages.to_sentence

    end

  end


  private


  def set_business
    @business = current_user.business
  end


  def set_settings
    @settings = @business.business_setting || @business.create_business_setting
  end


  def set_user
    @user = current_user
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


  def user_params
    params.permit(
      :first_name,
      :last_name,
      :email
    )
  end

end