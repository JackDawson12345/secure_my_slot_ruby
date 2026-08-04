class BusinessPortal::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :get_user_role
  before_action :get_subscribed?
  layout "business_dashboard"

  def get_user_role
    unless  current_user.role == "business"
      if current_user.role == "customer"
        redirect_to account_dashboard_path, notice: "You don't have permission to access this page."
      elsif current_user.role == "admin"
        redirect_to '/admin/dashboard', notice: "You don't have permission to access this page."
      end
    end
  end

  def get_subscribed?
    unless current_user.business.subscribed
      redirect_to business_subscription_path, notice: "A member of our marketing team will be in touch."
    end
  end
end