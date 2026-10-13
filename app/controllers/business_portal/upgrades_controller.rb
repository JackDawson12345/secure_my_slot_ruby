module BusinessPortal
  class UpgradesController < ApplicationController
    before_action :authenticate_user!

    def create
      business = current_user.business

      unless business
        redirect_back(
          fallback_location: root_path,
          alert: "Business not found."
        )
        return
      end

      SalesMailer.send_sales_email(
        business.sales_agent_name || "Unassigned",
        business.sales_agent_email || "support@uniteldirect.co.uk",
        business
      ).deliver_later

      redirect_to business_dashboard_path,
                  notice: "Thank you! Our marketing specialist will be in touch shortly."

    end
  end
end