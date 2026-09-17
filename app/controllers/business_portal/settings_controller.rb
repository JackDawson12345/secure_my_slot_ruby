class BusinessPortal::SettingsController < BusinessPortal::BaseController
  before_action :set_business
  before_action :set_settings
  before_action :set_user


  def index

  end

  def calendar_sync

  end

  def general_settings
  end

  def download
    url = params[:url]

    qrcode = RQRCode::QRCode.new(url)

    send_data(
      qrcode.as_png(
        bit_depth: 1,
        border_modules: 4,
        colour: "000",
        fill: "fff",
        size: 300
      ).to_s,
      filename: "qr-code.png",
      type: "image/png"
    )
  end


  def update
    Rails.logger.info "SETTINGS PARAMS: #{settings_params.inspect}"

    ActiveRecord::Base.transaction do
      @settings.update!(settings_params)

      @user.update!(user_params) if user_params.present?
    end

    category = params[:business_setting][:business_category]
    phone_number = params[:business_setting][:phone_number]

    @user.business.update!(category: category, phone_number: phone_number)
    @user.update!(phone_number: phone_number)

    redirect_to business_general_settings_path,
                notice: "Settings updated successfully."
  end


  def update_password

    unless @user.valid_password?(params[:current_password])
      redirect_to business_general_settings_path,
                  alert: "Current password is incorrect."
      return
    end


    if params[:password] != params[:password_confirmation]

      redirect_to business_general_settings_path,
                  alert: "Passwords do not match."

      return
    end


    if @user.update(
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

      redirect_to business_general_settings_path,
                  notice: "Password updated successfully."

    else

      redirect_to business_general_settings_path,
                  alert: @user.errors.full_messages.to_sentence

    end

  end

  def destroy_logo
    if @settings.logo.attached?
      @settings.logo.purge_later

      redirect_to business_general_settings_path,
                  notice: "Business logo removed successfully."
    else
      redirect_to business_general_settings_path,
                  alert: "No business logo was found."
    end
  end

  def remove_favicon
    if @settings.favicon.attached?
      @settings.favicon.purge_later

      redirect_to business_general_settings_path,
                  notice: "Favicon removed successfully."
    else
      redirect_to business_general_settings_path,
                  alert: "No favicon was found."
    end
  end

  def consultation_form
    @consultation_form =
      @business.consultation_form ||
      @business.build_consultation_form(
        name: "Consultation Form",
        structure: []
      )
  end

  def update_consultation_form
    @consultation_form =
      @business.consultation_form ||
      @business.build_consultation_form

    attributes = consultation_form_params

    if attributes[:structure].present?
      attributes[:structure] =
        JSON.parse(attributes[:structure])
    end

    if @consultation_form.update(attributes)
      redirect_to business_consultation_form_path,
                  notice: "Consultation form saved successfully."
    else
      render :consultation_form,
             status: :unprocessable_entity
    end
  end

  def email_templates
    @email_templates = @business.email_templates
  end


  def update_email_template

    @email_template = @business.email_templates.find_by!(
      template_type: params[:template_type]
    )


    if @email_template.update(email_template_params)

      redirect_to business_email_templates_path,
                  notice: "Email template updated successfully."

    else

      render :email_templates_edit,
             status: :unprocessable_entity

    end

  end

  def email_templates_edit
    unless EmailTemplate::TEMPLATE_TYPES.include?(params[:template_type])
      redirect_to business_email_templates_path, alert: "Invalid email template"
      return
    end

    @email_template = current_user.business.email_templates.find_or_create_by!(
      template_type: params[:template_type]
    ) do |template|
      template.subject = default_subject(params[:template_type])
      template.body = default_body(params[:template_type])
    end
  end

  def birthday_reminder
    @birthday_reminder_message =
      @business.birthday_reminder_message ||
      @business.create_birthday_reminder_message(
        text: "Happy Birthday {{customer_name}}! 🎂 We hope you have a fantastic day. Thank you for being a valued customer and we look forward to seeing you again soon."
      )
  end

  def update_birthday_reminder

    @birthday_reminder_message =
      @business.birthday_reminder_message ||
      @business.build_birthday_reminder_message


    if @birthday_reminder_message.update(birthday_reminder_params)

      redirect_to business_birthday_reminder_path,
                  notice: "Birthday reminder saved successfully."

    else

      render :birthday_reminder,
             status: :unprocessable_entity

    end

  end


  private

  def birthday_reminder_params
    params.require(:birthday_reminder_message)
          .permit(:text)
  end

  def default_subject(template_type)
    case template_type
    when "confirmation"
      "Your booking has been confirmed"
    when "reminder"
      "Reminder: Your upcoming appointment"
    else
      "Your appointment details"
    end
  end


  def default_body(template_type)
    case template_type

    when "confirmation"
      <<~TEXT
      Hi {{customer_name}},

      Your appointment has been confirmed with {{business_name}}.

      Service:
      {{service_name}}

      Date:
      {{appointment_date}}

      Time:
      {{appointment_time}}

      Remaining balance:
      {{remaining_balance}}

      Consultation form:
      {{consultation_form_url}}

      We look forward to seeing you.

      Thanks,
      {{business_name}}
    TEXT


    when "reminder"
      <<~TEXT
      Hi {{customer_name}},

      This is a reminder that your appointment with {{business_name}} starts soon.

      Service:
      {{service_name}}

      Date:
      {{appointment_date}}

      Time:
      {{appointment_time}}

      Remaining balance:
      {{remaining_balance}}

      Consultation form:
      {{consultation_form_url}}

      We look forward to seeing you.

      Thanks,
      {{business_name}}
    TEXT


    else
      ""
    end
  end

  def email_template_params
    params.require(:email_template).permit(
      :subject,
      :body
    )
  end

  def consultation_form_params
    params.require(:consultation_form).permit(
      :name,
      :structure
    )
  end


  def set_business
    @business = current_user.business
  end


  def set_settings
    @settings = @business.business_setting || @business.create_business_setting
  end


  def set_user
    @user = current_user
  end


  def settings_params
    params.require(:business_setting).permit(
      :business_name,
      :business_category,
      :phone_number,
      :business_email,
      :business_description,
      :logo,
      :favicon,
      :check_verify_link,

      :address_line_1,
      :address_line_2,
      :town_or_city,
      :postcode,
      :country,

      :booking_page_live,
      :automatically_confirm_bookings,
      :allow_customer_cancellations,
      :require_customer_phone_number,
      :cancellation_notice_hours,

      :new_booking_notifications,
      :cancellation_notifications,
      :daily_appointment_summary,
      :birthday_reminder
    )
  end


  def user_params
    params.permit(
      :first_name,
      :last_name,
      :email
    )
  end

end