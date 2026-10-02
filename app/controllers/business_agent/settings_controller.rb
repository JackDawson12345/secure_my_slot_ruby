class BusinessAgent::SettingsController < BusinessAgent::BaseController
  before_action :set_user

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to business_agent_settings_path,
                  notice: "Settings updated successfully."
    else
      flash.now[:alert] = "Please correct the errors below."
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = @business_agent.user
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :password,
      :password_confirmation
    )
  end
end