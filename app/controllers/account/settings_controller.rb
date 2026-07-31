class Account::SettingsController < Account::BaseController
  def show
    @customer_settings = current_user.customer_setting || current_user.build_customer_setting
  end

  def update
    @customer_settings = current_user.customer_setting || current_user.build_customer_setting

    user_ok = update_user
    settings_ok = @customer_settings.update(customer_setting_params)

    if user_ok && settings_ok
      redirect_to account_settings_path, notice: "Your settings have been updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  # Only touch the password fields if the user actually filled them in.
  # Devise's update_with_password requires current_password to be correct;
  # if no new password was submitted, do a plain attribute update instead
  # so people can save their name/email without re-entering their password.
  def update_user
    if user_params[:password].present?
      current_user.update_with_password(user_params)
    else
      current_user.update(user_params.except(:password, :password_confirmation, :current_password))
    end
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :password,
      :password_confirmation,
      :current_password,
      :profile_photo
    )
  end

  def customer_setting_params
    params.require(:customer_setting).permit(
      :date_of_birth,
      :preferred_name,
      :phone_number,
      :preferred_contact_method,
      :address_line_1,
      :address_line_2,
      :town_or_city,
      :postcode,
      :country,
      :booking_confirmations,
      :appointment_reminders,
      :booking_changes,
      :offers_and_service_updates,
      :reminder_timing,
      :reminder_method
    )
  end
end