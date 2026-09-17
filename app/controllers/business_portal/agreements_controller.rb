class BusinessPortal::AgreementsController < BusinessPortal::BaseController

  before_action :set_agreement, only: [:edit, :update, :destroy]


  def index
    @agreements = current_user.business.agreements.order(created_at: :desc)
  end


  def new
    @agreement = current_user.business.agreements.build
  end


  def create
    @agreement = current_user.business.agreements.build(agreement_params)

    if @agreement.save
      redirect_to business_agreements_path,
                  notice: "Agreement created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end


  def edit

  end


  def update
    if @agreement.update(agreement_params)
      redirect_to business_agreements_path,
                  notice: "Agreement updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    @agreement.destroy

    redirect_to business_agreements_path,
                notice: "Agreement deleted successfully."
  end

  def send_agreement

    business = Business.find(params['business_id'])
    booking = Booking.find(params['booking_id'])
    agreement = Agreement.find(params['id'])
    token = SecureRandom.uuid

    AgreementStatus.create(business: business, booking: booking, agreement: agreement, status: 'pending', token: token)
    AgreementMailer.sign_agreement(agreement, booking, business).deliver_now

    redirect_to business_booking_path(params['booking_id']), notice: "Agreement sent successfully."
  end


  private


  def set_agreement
    @agreement = current_user.business.agreements.find(params[:id])
  end


  def agreement_params
    params.require(:agreement).permit(
      :name,
      :content
    )
  end

end