class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters,
                if: :devise_controller?

  before_action :set_visitor_id

  helper WebsiteColourHelper


  def after_omniauth_failure_path_for(scope)
    business_calendar_sync_path
  end


  rescue_from StandardError do |exception|

    ErrorNotifier.notify(
      exception,
      request,
      current_user
    )

    raise exception

  end


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
    when "agent"
      business_agent_dashboard_path
    else
      root_path
    end
  end


  private

  def set_visitor_id
    cookies[:visitor_id] ||= SecureRandom.uuid
  end


  def track_page_view(record)

    visitor_id = cookies[:visitor_id]

    recent_view = record.page_views
                        .where(visitor_id: visitor_id)
                        .where("created_at > ?", 5.minutes.ago)
                        .exists?

    return if recent_view


    record.page_views.create!(
      visitor_id: visitor_id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referrer: request.referrer
    )

  end

end