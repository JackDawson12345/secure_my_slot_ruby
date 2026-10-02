class AdminMailer < ApplicationMailer

  def system_error(exception, request, user)

    @exception = exception
    @request = request
    @user = user

    mail(
      to: [
        "support@book-pilot.co.uk",
        "support@uniteldirect.co.uk"
      ],
      subject: "BookPilot Error: #{exception.class}"
    )

  end

end