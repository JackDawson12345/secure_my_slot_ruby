class CustomerAccountMailer < ApplicationMailer
  def welcome_with_password_setup(user)
    @user = user

    @token = @user.send(:set_reset_password_token)

    @reset_password_url = edit_user_password_url(
      reset_password_token: @token,
      host: "www.securemyslot.co.uk",
      protocol: "https"
    )

    mail(
      to: @user.email,
      subject: "Set up your SecureMySlot account"
    )
  end
end