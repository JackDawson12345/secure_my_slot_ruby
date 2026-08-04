class Admin::SettingsController < Admin::BaseController
  def index
  end

  def update
    if current_user.update(settings_params)
      redirect_to admin_settings_path,
                  notice: "Settings updated successfully."
    else
      render :index,
             status: :unprocessable_entity
    end
  end

  def update_password
    if current_user.update(password_params)
      bypass_sign_in(current_user)

      redirect_to admin_settings_path,
                  notice: "Password updated successfully."
    else
      redirect_to admin_settings_path,
                  alert: current_user.errors.full_messages.to_sentence
    end
  end

  private

  def settings_params
    params.require(:user)
          .permit(
            :first_name,
            :last_name,
            :email
          )
  end

  def password_params
    params.permit(
      :password,
      :password_confirmation
    )
  end
end