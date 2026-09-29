class BusinessAgent::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :get_user_role
  before_action :get_business
  before_action :set_business_agent
  layout "business_agent"


  def get_user_role
    unless  current_user.role == "agent"
      if current_user.role == "customer"
        redirect_to account_dashboard_path, notice: "You don't have permission to access this page."
      elsif current_user.role == "admin"
        redirect_to '/admin/dashboard', notice: "You don't have permission to access this page."
      elsif current_user.role == "business"
        redirect_to '/admin/dashboard', notice: "You don't have permission to access this page."
      end
    end
  end

  def get_business
    @business = BusinessAgent.find_by(user_id: current_user.id).business
  end

  def set_business_agent
    @business_agent = BusinessAgent.find_by!(user_id: current_user.id)
  end

end