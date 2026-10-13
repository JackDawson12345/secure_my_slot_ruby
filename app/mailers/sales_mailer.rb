class SalesMailer < ApplicationMailer
  def send_sales_email(sales_agent_name, sales_agent_email, business)
    @business = business
    @sales_agent_name = sales_agent_name
    @sales_agent_email = sales_agent_email

    mail(
      to: [
        @sales_agent_email,
        "dave@uniteldirect.co.uk",
        "support@uniteldirect.co.uk"
      ].uniq,
      subject: "Business Requested An Upgrade: #{@business.business_name}"
    )
  end
end