class Pages::WebsiteController < ApplicationController
  def home
  end

  def about_us

  end

  def contact_us

  end

  def features

  end

  def payments_success
    @booking = Booking.find(params[:id])
    @business = @booking.business
  end

  def create
    ContactMailer
      .with(
        first_name: contact_params[:first_name],
        last_name: contact_params[:last_name],
        email: contact_params[:email],
        business_name: contact_params[:business_name],
        enquiry_type: contact_params[:enquiry_type],
        subject: contact_params[:subject],
        message: contact_params[:message]
      )
      .contact_enquiry
      .deliver_later

    redirect_to contact_path,
                notice: "Thanks for getting in touch. Your message has been sent."
  rescue StandardError => e
    Rails.logger.error("Contact form error: #{e.message}")

    flash.now[:alert] = "We couldn't send your message. Please try again."

    render :new, status: :unprocessable_entity
  end

  def privacy_policy

  end

  def terms_of_use

  end

  private

  def contact_params
    params.permit(
      :first_name,
      :last_name,
      :email,
      :business_name,
      :enquiry_type,
      :subject,
      :message,
      :privacy_accepted
    )
  end

end
