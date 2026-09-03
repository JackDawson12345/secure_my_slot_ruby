class BookingMailer < ApplicationMailer

  def appointment_reminder
    set_booking_details
    set_consultation_details

    @email_content = email_body("reminder")

    mail(
      to: @user.email,
      subject: email_subject("reminder")
    )
  end


  def customer_booking_confirmation
    set_booking_details
    set_consultation_details

    @email_content = email_body("confirmation")

    mail(
      to: @user.email,
      subject: email_subject("confirmation")
    )
  end


  def business_booking_notification
    set_booking_details

    mail(
      to: @business.user.email,
      subject: "New booking received - #{@service.name}"
    )
  end


  def booking_cancelled
    set_booking_details

    mail(
      to: @business.user.email,
      subject: "Booking cancelled - #{@service.name}"
    )
  end


  def daily_appointment_summary
    @business = params[:business]
    @bookings = params[:bookings]
    @date = params[:date]

    mail(
      to: @business.user.email,
      subject: "Your appointments for #{@date.strftime('%A %-d %B')}"
    )
  end


  def status_changed
    set_booking_details
    set_consultation_details

    @email_content = email_body("confirmation")

    mail(
      to: @user.email,
      subject: email_subject("confirmation")
    )
  end


  private


  def set_booking_details

    @booking = params[:booking]

    @business = @booking.business
    @service = @booking.service
    @user = @booking.user


    service_price = @service.price || 0
    amount_paid = @booking.amount_paid || 0


    @remaining_balance = [
      service_price - amount_paid,
      0
    ].max

  end


  def set_consultation_details

    @consultation_required =
      @business.consultation_form.present? &&
      @booking.consultation_token.present? &&
      @booking.consultation_responses.blank?


    return unless @consultation_required


    @consultation_form_url =
      business_site_consultation_form_url(
        token: @booking.consultation_token,
        subdomain: @business.page_address
      )

  end


  def email_subject(template_type)

    template = @business.email_templates.find_by(
      template_type: template_type
    )


    return template.subject if template.present?


    case template_type

    when "confirmation"
      "Booking confirmed with #{@business.business_name}"

    when "reminder"
      "Reminder: your appointment is in one hour"

    end

  end


  def email_body(template_type)

    template = @business.email_templates.find_by(
      template_type: template_type
    )


    return default_email_body(template_type) unless template.present?


    template.body
            .gsub("{{customer_name}}", @user.first_name.to_s)
            .gsub("{{business_name}}", @business.business_name.to_s)
            .gsub("{{service_name}}", @service.name.to_s)
            .gsub(
              "{{appointment_date}}",
              @booking.date.strftime("%-d %B %Y")
            )
            .gsub(
              "{{appointment_time}}",
              @booking.time.strftime("%-I:%M %p")
            )
            .gsub(
              "{{remaining_balance}}",
              @remaining_balance.positive? ? "£#{format('%.2f', @remaining_balance)}" : "No remaining balance"
            )
            .gsub(
              "{{consultation_form_url}}",
              @consultation_form_url.to_s
            )

  end


  def default_email_body(template_type)

    case template_type

    when "confirmation"

      <<~TEXT
        Hi #{@user.first_name},

        Your appointment has been confirmed with #{@business.business_name}.

        Service:
        #{@service.name}

        Date:
        #{@booking.date.strftime("%-d %B %Y")}

        Time:
        #{@booking.time.strftime("%-I:%M %p")}

        We look forward to seeing you.

        Thanks,
        #{@business.business_name}
      TEXT


    when "reminder"

      <<~TEXT
        Hi #{@user.first_name},

        This is a reminder that your appointment with #{@business.business_name} starts soon.

        Service:
        #{@service.name}

        Date:
        #{@booking.date.strftime("%-d %B %Y")}

        Time:
        #{@booking.time.strftime("%-I:%M %p")}

        We look forward to seeing you.

        Thanks,
        #{@business.business_name}
      TEXT

    end

  end

end