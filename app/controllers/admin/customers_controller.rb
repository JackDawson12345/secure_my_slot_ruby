class Admin::CustomersController < Admin::BaseController
  TABS = %w[
    overview
    bookings
    customers
    services
    opening_hours
    website_settings
    settings
  ].freeze

  def index
    customer_scope = User
                       .where(role: 1)
                       .left_joins(business: :business_setting)
                       .includes(
                         business: [
                           :business_setting,
                           :services,
                           :bookings
                         ]
                       )
                       .distinct

    @total_customers = User.where(role: 1).count

    @new_customers_this_month = User
                                  .where(role: 1)
                                  .where(created_at: Time.current.beginning_of_month..)
                                  .count

    @active_customers = User
                          .where(role: 1)
                          .joins(business: :business_setting)
                          .where(
                            business_settings: {
                              booking_page_live: true
                            }
                          )
                          .distinct
                          .count

    @total_bookings = Booking
                        .joins(business: :user)
                        .where(users: { role: 1 })
                        .count

    if params[:query].present?
      search_term = ActiveRecord::Base.sanitize_sql_like(
        params[:query].strip
      )

      customer_scope = customer_scope.where(
        <<~SQL.squish,
          users.first_name ILIKE :query
          OR users.last_name ILIKE :query
          OR users.email ILIKE :query
          OR users.phone_number ILIKE :query
          OR businesses.business_name ILIKE :query
          OR businesses.page_address ILIKE :query
        SQL
        query: "%#{search_term}%"
      )
    end

    case params[:status]
    when "live"
      customer_scope = customer_scope.where(
        business_settings: {
          booking_page_live: true
        }
      )
    when "offline"
      customer_scope = customer_scope.where(
        "business_settings.booking_page_live = ? " \
          "OR business_settings.booking_page_live IS NULL",
        false
      )
    end

    @customers = customer_scope.order(created_at: :desc)
  end

  def new
    @customer = User.new
    build_new_customer_records
  end

  def create
    @customer = User.new(customer_params)
    @customer.role = 1

    @business = @customer.build_business(
      business_params.merge(subscribed: true)
    )

    @business_setting = @business.build_business_setting(
      business_setting_params
    )

    @business_website = @business.build_business_website(
      colour: "indigo"
    )

    ActiveRecord::Base.transaction do
      @customer.save!
    end

    redirect_to admin_customer_path(@customer),
                notice: "Customer and business were created successfully."
  rescue ActiveRecord::RecordInvalid => error
    prepare_failed_create(error.record)

    flash.now[:alert] =
      "The customer could not be created. Please check the form."

    render :new, status: :unprocessable_entity
  end

  def show
    @customer = User
                  .where(role: 1)
                  .includes(
                    business: [
                      :business_setting,
                      :business_website,
                      :opening_hours,
                      :services,
                      {
                        bookings: [
                          :service,
                          :user
                        ]
                      }
                    ]
                  )
                  .find(params[:id])

    @business = @customer.business
    @active_tab = permitted_tab

    return unless @business

    @bookings = @business.bookings
                         .includes(:service, :user)
                         .order(date: :desc, time: :desc)

    @services = @business.services.order(:name)
    @opening_hours = @business.opening_hours

    @booking_customers = User
                           .joins(:bookings)
                           .where(bookings: { business_id: @business.id })
                           .distinct
                           .order(:first_name, :last_name, :email)

    @total_bookings = @bookings.size
    @total_services = @services.size
    @total_booking_customers = @booking_customers.size

    @upcoming_bookings = @bookings.select do |booking|
      booking_starts_at(booking)&.future?
    end

    @completed_bookings = @bookings.select do |booking|
      booking_starts_at(booking)&.past?
    end
  end

  private

  def customer_params
    params.require(:customer).permit(
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :password,
      :password_confirmation,
      :terms_accepted,
      :marketing_consent
    )
  end

  def business_params
    params.require(:business).permit(
      :business_name,
      :page_address
    )
  end

  def business_setting_params
    params.require(:business_setting).permit(
      :business_name,
      :business_category,
      :phone_number,
      :business_email,
      :business_description,
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
      :daily_appointment_summary
    )
  end

  def build_new_customer_records
    @business = @customer.build_business
    @business_setting = @business.build_business_setting(
      booking_page_live: false,
      automatically_confirm_bookings: true,
      allow_customer_cancellations: true,
      require_customer_phone_number: true,
      cancellation_notice_hours: 24,
      new_booking_notifications: true,
      cancellation_notifications: true,
      daily_appointment_summary: false,
      country: "United Kingdom"
    )
  end

  def prepare_failed_create(invalid_record)
    @business ||= @customer.business || @customer.build_business

    @business_setting ||=
      @business.business_setting ||
      @business.build_business_setting

    case invalid_record
    when User
      @customer = invalid_record
    when Business
      @business = invalid_record
    when BusinessSetting
      @business_setting = invalid_record
    end
  end

  def permitted_tab
    params[:tab].presence_in(TABS) || "overview"
  end

  def booking_starts_at(booking)
    return if booking.date.blank? || booking.time.blank?

    Time.zone.parse(
      "#{booking.date} #{booking.time.strftime('%H:%M')}"
    )
  end
end