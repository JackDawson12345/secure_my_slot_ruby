class CustomEmailTemplateMailer < ApplicationMailer
  def custom_email_template(template, booking)
    @template = template
    @booking = booking
    @user = booking.user

    @template.attachments.each do |attachment|
      attachments[attachment.filename.to_s] = {
        mime_type: attachment.content_type,
        content: attachment.download
      }
    end

    mail(
      to: @user.email,
      subject: @template.subject
    )
  end
end