class SignUpMailer < ApplicationMailer
  def business_sign_up
    @business = params[:business]


    mail(
      to: [
        "support@book-pilot.co.uk",
        "support@uniteldirect.co.uk"
      ],
      subject: "A new business registration"
    )
  end
end