class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters,
                if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: [
        :first_name,
        :last_name,
        :phone_number,
        :terms_accepted,
        :marketing_consent
      ]
    )

    devise_parameter_sanitizer.permit(
      :account_update,
      keys: [
        :first_name,
        :last_name,
        :phone_number,
        :marketing_consent
      ]
    )
  end

  def after_sign_in_path_for(resource)
    case resource.role
    when "admin"
      admin_dashboard_path
    when "business"
      business_dashboard_path
    when "customer"
      account_dashboard_path
    else
      root_path
    end
  end
end