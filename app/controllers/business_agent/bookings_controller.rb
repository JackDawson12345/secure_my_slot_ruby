class BusinessAgent::BookingsController < BusinessAgent::BaseController


  def index
    bookings = @business.bookings
                        .includes(:user, :service, :agent)

    today = Date.current
    current_time = Time.current

    # ----------------------------------------
    # Booking ownership / visibility
    # ----------------------------------------

    @can_view_all_bookings =
      @business_agent_settings.booking_visibility == "all_bookings"

    if @can_view_all_bookings
      @booking_view =
        %w[mine all].include?(params[:view]) ? params[:view] : "mine"

      bookings_scope =
        if @booking_view == "all"
          bookings
        else
          bookings.where(agent_id: @business_agent.user.id)
        end
    else
      @booking_view = "mine"

      bookings_scope =
        bookings.where(agent_id: @business_agent.user.id)
    end

    # ----------------------------------------
    # Statistics
    # Based on current ownership view
    # ----------------------------------------

    todays_bookings = bookings_scope.where(date: today)

    @today_count = todays_bookings.count

    @today_confirmed_count =
      todays_bookings.where(status: :confirmed).count

    @today_pending_count =
      todays_bookings.where(status: :pending).count

    @upcoming_count = bookings_scope
                        .where(date: today..(today + 7.days))
                        .where(
                          "date > :today OR (date = :today AND time >= :current_time)",
                          today: today,
                          current_time: current_time
                        )
                        .count

    @completed_count = bookings_scope
                         .where(status: :completed)
                         .where(date: today.beginning_of_month..today.end_of_month)
                         .count

    @cancelled_count = bookings_scope
                         .where(status: :cancelled)
                         .where(date: today.beginning_of_month..today.end_of_month)
                         .count

    # ----------------------------------------
    # Counts for My / All tabs
    # ----------------------------------------

    @my_bookings_count =
      bookings.where(agent_id: @business_agent.user.id).count

    @all_bookings_count =
      @can_view_all_bookings ? bookings.count : @my_bookings_count

    # ----------------------------------------
    # Services
    # ----------------------------------------

    @services = @business.services.order(:name)

    # ----------------------------------------
    # Base scope
    # ----------------------------------------

    bookings_scope = bookings_scope.order(
      date: :asc,
      time: :asc
    )

    # ----------------------------------------
    # Status
    # ----------------------------------------

    if params[:status].present? &&
       %w[confirmed pending completed cancelled].include?(params[:status])

      bookings_scope =
        bookings_scope.where(status: params[:status])
    end

    # ----------------------------------------
    # Search
    # ----------------------------------------

    if params[:q].present?
      search =
        "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

      bookings_scope = bookings_scope
                         .joins(:user, :service)
                         .where(
                           <<~SQL.squish,
            users.first_name ILIKE :search
            OR users.last_name ILIKE :search
            OR users.email ILIKE :search
            OR services.name ILIKE :search
          SQL
                           search: search
                         )
    end

    # ----------------------------------------
    # Service
    # ----------------------------------------

    if params[:service_id].present?
      bookings_scope =
        bookings_scope.where(service_id: params[:service_id])
    end

    # ----------------------------------------
    # Dates
    # ----------------------------------------

    if params[:date_from].present?
      bookings_scope =
        bookings_scope.where(
          "bookings.date >= ?",
          params[:date_from]
        )
    end

    if params[:date_to].present?
      bookings_scope =
        bookings_scope.where(
          "bookings.date <= ?",
          params[:date_to]
        )
    end

    # ----------------------------------------
    # Pagination
    # ----------------------------------------

    @per_page = 10

    @current_page = params[:page].to_i
    @current_page = 1 if @current_page < 1

    @total_bookings = bookings_scope.count

    @total_pages =
      if @total_bookings.positive?
        (@total_bookings.to_f / @per_page).ceil
      else
        1
      end

    @current_page = @total_pages if @current_page > @total_pages

    @bookings = bookings_scope
                  .offset((@current_page - 1) * @per_page)
                  .limit(@per_page)

    @booking_start =
      if @total_bookings.zero?
        0
      else
        ((@current_page - 1) * @per_page) + 1
      end

    @booking_end = [
      @current_page * @per_page,
      @total_bookings
    ].min
  end

  def show
    @booking = accessible_bookings
                 .includes(:user, :service, :agent)
                 .find(params[:id])

    @agreements = @business.agreements

    @email_templates = @business.email_templates
                                .where(custom: true)
  end

  def update_status
    @booking = accessible_bookings.find(params[:booking_id])

    new_status = params[:status]

    allowed_transitions = {
      "pending"   => ["confirmed"],
      "confirmed" => ["completed"],
      "completed" => ["confirmed"]
    }

    unless allowed_transitions
             .fetch(@booking.status, [])
             .include?(new_status)

      redirect_to business_agent_booking_path(@booking),
                  alert: "That booking status change is not allowed."
      return
    end

    if @booking.update(status: new_status)

      message =
        case new_status
        when "confirmed"
          "Booking marked as confirmed."
        when "completed"
          "Booking marked as completed."
        else
          "Booking status updated."
        end

      if @booking.user.customer_setting&.booking_changes
        BookingMailer
          .with(booking: @booking)
          .status_changed
          .deliver_now

        SendBookingStatusChangeSmsJob.perform_later(@booking.id)
      end

      redirect_to business_agent_booking_path(@booking),
                  notice: message

    else

      redirect_to business_agent_booking_path(@booking),
                  alert: "Could not update the booking status."

    end
  end

  def agreement_show
    @agreement_status = AgreementStatus.find_by(token: params[:token])

    return redirect_to root_path unless @agreement_status

    @agreement = @agreement_status.agreement
    @booking = @agreement_status.booking
  end


  def send_agreement
    business = Business.find(params['business_id'])
    booking = accessible_bookings.find(params[:id])
    agreement = Agreement.find(params['agreement_id'])
    token = SecureRandom.uuid


    AgreementStatus.create(business: business, booking: booking, agreement: agreement, status: 'pending', token: token)
    AgreementMailer.sign_agreement(agreement, booking, business).deliver_now

    redirect_to business_agent_booking_path(params['id']), notice: "Agreement sent successfully."
  end

  def agreements_pdf
    @agreement_status = AgreementStatus.find_by(token: params[:token])

    return redirect_to root_path unless @agreement_status

    @agreement = @agreement_status.agreement
    @booking = @agreement_status.booking


    respond_to do |format|

      format.pdf do

        render pdf: "#{@agreement.name}",
               template: "business_agent/bookings/agreement_pdf",
               layout: "pdf",
               disposition: "attachment"

      end

    end
  end


  def email_template
    business = @business
    booking = Booking.find(params['booking_id'])
    template = EmailTemplate.find(params['email_template_id'])
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



    redirect_to business_agent_booking_path(params['booking_id']), notice: "Email sent successfully."
  end

  def accessible_bookings
    scope = @business.bookings

    if @business_agent_settings.booking_visibility == "all_bookings"
      scope
    else
      scope.where(agent_id: @business_agent.user.id)
    end
  end

end