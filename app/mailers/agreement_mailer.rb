class AgreementMailer < ApplicationMailer

  def sign_agreement(agreement, booking, business)
    @agreement = agreement
    @booking = booking
    @business = business
    @agreement_status = AgreementStatus.find_by(agreement: @agreement, booking: @booking, business: @business)

    mail(
      to: @booking.user.email,
      subject: "Your agreement is ready to sign for #{@business.business_name}",
    )
  end

end