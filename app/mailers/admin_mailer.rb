class AdminMailer < ApplicationMailer

  def system_error(exception, request, user)

    @exception = exception
    @request = request
    @user = user

    mail(
      to: [
        "support@securemyslot.co.uk",
        "support@uniteldirect.co.uk"
      ],
      subject: "SecureMySlot Error: #{exception.class}"
    )

  end

end