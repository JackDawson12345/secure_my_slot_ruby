class BusinessPortal::CustomEmailTemplatesController < BusinessPortal::BaseController
  before_action :set_email_template, only: [:edit, :update, :destroy]

  def index
    @email_templates = current_user.business.email_templates.where(custom: true)
  end

  def new
    @email_template = current_user.business.email_templates.new(
      custom: true
    )
  end

  def create
    @email_template = current_user.business.email_templates.new(
      email_template_params.except(:attachments)
    )

    @email_template.custom = true

    if @email_template.save
      attachments = params.dig(:email_template, :attachments)

      if attachments.present?
        attachments.reject(&:blank?).each do |attachment|
          @email_template.attachments.attach(attachment)
        end
      end

      redirect_to business_email_templates_custom_templates_path,
                  notice: "Email template created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @email_template.update(
      email_template_params.except(:attachments, :remove_attachment_ids)
    )

      # Remove selected attachments
      remove_attachment_ids.each do |attachment_id|
        attachment = @email_template.attachments.find_by(id: attachment_id)
        attachment&.purge
      end

      # Add new attachments
      new_attachments.each do |attachment|
        @email_template.attachments.attach(attachment)
      end

      redirect_to business_email_templates_custom_templates_path,
                  notice: "Email template updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @email_template.destroy

    redirect_to business_email_templates_custom_templates_path,
                notice: "Email template deleted successfully."
  end

  def send_email
    business = Business.find(params['business_id'])
    booking = Booking.find(params['booking_id'])
    template = EmailTemplate.find(params['id'])
    token = SecureRandom.uuid

    if params[:send_count] =="resend"
      CustomEmailTemplateMailer
        .custom_email_template(template, booking)
        .deliver_later
    else
      CustomEmailTemplateStatus.create(business: business, booking: booking, email_template: template, status: 'sent', token: token)
      CustomEmailTemplateMailer
        .custom_email_template(template, booking)
        .deliver_later
    end



    redirect_to business_booking_path(params['booking_id']), notice: "Email sent successfully."
  end

  private

  def set_email_template
    @email_template = current_user.business.email_templates.where(custom: true).find(params[:id])
  end

  def email_template_params
    params.require(:email_template).permit(
      :template_type,
      :subject,
      :body,
      attachments: [],
      remove_attachment_ids: []
    )
  end

  def remove_attachment_ids
    Array(params.dig(:email_template, :remove_attachment_ids)).reject(&:blank?)
  end

  def new_attachments
    Array(params.dig(:email_template, :attachments)).reject(&:blank?)
  end
end