# app/mailers/contact_mailer.rb

class ContactMailer < ApplicationMailer
  def contact_enquiry
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @email = params[:email]
    @business_name = params[:business_name]
    @enquiry_type = params[:enquiry_type]
    @subject = params[:subject]
    @message = params[:message]

    mail(
      to: [
        "support@securemyslot.co.uk",
        "support@uniteldirect.co.uk"
      ],
      reply_to: @email,
      subject: "SecureMySlot Contact: #{@subject}"
    )
  end
end