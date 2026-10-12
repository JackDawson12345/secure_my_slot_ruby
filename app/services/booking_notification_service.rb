
class BookingNotificationService
  def self.created(booking)
    new(booking).created
  end
  def self.status_changed(booking, previous_status:)
    new(booking).status_changed(
      previous_status: previous_status
    )
  end

  def initialize(booking)
    @booking = booking
    @business = booking.business
    @customer = booking.user
    @agent = booking.agent
  end

  def created
    notify_business
    notify_agent
    notify_customer
  end

  def status_changed(previous_status:)
    return if previous_status.to_s == @booking.status.to_s

    # Respect the customer's notification preferences
    return unless @customer.customer_setting&.booking_changes?

    title, body =
      case @booking.status
      when "confirmed"
        [
          "Booking Confirmed",
          "Your #{service_name} appointment with " \
            "#{@business.business_name} on #{booking_date_time} " \
            "has been confirmed."
        ]

      when "completed"
        [
          "Appointment Completed",
          "Your #{service_name} appointment with " \
            "#{@business.business_name} has been marked as completed."
        ]

      when "cancelled"
        [
          "Booking Cancelled",
          "Your #{service_name} appointment with " \
            "#{@business.business_name} on #{booking_date_time} " \
            "has been cancelled."
        ]

      when "pending"
        [
          "Booking Pending",
          "Your #{service_name} appointment with " \
            "#{@business.business_name} is now pending confirmation."
        ]

      else
        [
          "Booking Updated",
          "The status of your #{service_name} appointment " \
            "with #{@business.business_name} has changed."
        ]
      end

    queue_notification(
      user: @customer,
      title: title,
      body: body,
      type: "booking_status_changed"
    )
  end

  private

  def notify_business
    return unless @business.business_setting
    return unless @business.business_setting.new_booking_notifications?

    owner = @business.user
    return unless owner

    queue_notification(
      user: owner,
      title: "New Booking",
      body: "#{customer_name} has booked #{service_name} for #{booking_date_time}.",
      type: "new_booking"
    )
  end

  def notify_agent
    return unless @agent
    return if @agent.id == @business.user_id

    queue_notification(
      user: @agent,
      title: "New Appointment Assigned",
      body: "You have a new #{service_name} appointment on #{booking_date_time}.",
      type: "agent_booking"
    )
  end

  def notify_customer
    return unless @customer.customer_setting&.booking_confirmations?

    if @booking.status == "confirmed"
      title = "Booking Confirmed"
      body = "Your #{service_name} appointment with #{@business.business_name} is confirmed for #{booking_date_time}."
    else
      title = "Booking Received"
      body = "Your #{service_name} appointment request with #{@business.business_name} has been received for #{booking_date_time}."
    end

    queue_notification(
      user: @customer,
      title: title,
      body: body,
      type: "customer_booking"
    )
  end

  def queue_notification(user:, title:, body:, type:)
    return unless user.push_tokens.exists?

    SendPushNotificationJob.perform_later(
      user.id,
      title,
      body,
      {
        type: type,
        booking_id: @booking.id,
        business_id: @business.id,
        status: @booking.status
      }
    )
  end

  def customer_name
    @customer.full_name.presence || "A customer"
  end

  def service_name
    @booking.service.name
  end

  def booking_date_time
    date = @booking.date.strftime("%d %B %Y")
    time = @booking.time.strftime("%H:%M")

    "#{date} at #{time}"
  end
end
