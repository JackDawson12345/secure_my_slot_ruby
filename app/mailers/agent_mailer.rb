class AgentMailer < ApplicationMailer
  def invitation(agent, business, token)
    @agent = agent
    @business = business
    @token = token

    mail(
      to: @agent.email,
      subject: "You've been invited to join #{@business.business_name}"
    )
  end
end