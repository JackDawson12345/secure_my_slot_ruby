class Account::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :get_user_role
  layout "account_dashboard"

  def get_user_role
    unless  current_user.role == "customer"
      if current_user.role == "business"
        redirect_to business_dashboard_path, notice: "You don't have permission to access this page."
      elsif current_user.role == "admin"
        redirect_to '/admin/dashboard', notice: "You don't have permission to access this page."
      end
    end
  end
end