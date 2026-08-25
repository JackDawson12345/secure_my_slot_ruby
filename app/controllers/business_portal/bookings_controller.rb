# app/controllers/business_portal/bookings_controller.rb

class BusinessPortal::BookingsController < BusinessPortal::BaseController
  def index
    @business = current_user.business

    bookings = @business.bookings.includes(:user, :service)

    today = Date.current
    current_time = Time.current

    # ----------------------------------------
    # Statistics
    # ----------------------------------------

    todays_bookings = @business.bookings.where(date: today)

    @today_count = todays_bookings.count
    @today_confirmed_count = todays_bookings.where(status: :confirmed).count
    @today_pending_count = todays_bookings.where(status: :pending).count

    @upcoming_count = @business.bookings
                               .where(date: today..(today + 7.days))
                               .where(
                                 "date > :today OR (date = :today AND time >= :current_time)",
                                 today: today,
                                 current_time: current_time
                               )
                               .count

    @completed_count = @business.bookings
                                .where(status: :completed)
                                .where(date: today.beginning_of_month..today.end_of_month)
                                .count

    @cancelled_count = @business.bookings
                                .where(status: :cancelled)
                                .where(date: today.beginning_of_month..today.end_of_month)
                                .count

    # ----------------------------------------
    # Services for filter dropdown
    # ----------------------------------------

    @services = @business.services.order(:name)

    # ----------------------------------------
    # Base booking scope
    # ----------------------------------------

    bookings_scope = bookings.order(date: :asc, time: :asc)

    # ----------------------------------------
    # Status filter
    # ----------------------------------------

    if params[:status].present? &&
       %w[confirmed pending completed cancelled].include?(params[:status])

      bookings_scope = bookings_scope.where(status: params[:status])
    end

    # ----------------------------------------
    # Search
    # ----------------------------------------

    if params[:q].present?
      search = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

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
    # Service filter
    # ----------------------------------------

    if params[:service_id].present?
      bookings_scope = bookings_scope.where(service_id: params[:service_id])
    end

    # ----------------------------------------
    # Date filters
    # ----------------------------------------

    if params[:date_from].present?
      bookings_scope = bookings_scope.where(
        "bookings.date >= ?",
        params[:date_from]
      )
    end

    if params[:date_to].present?
      bookings_scope = bookings_scope.where(
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

  def add_booking
    @business = current_user.business
  end

  def show
    @business = current_user.business
    @booking = @business.bookings.find(params[:id])
  end

  def create
    @business = current_user.business

    begin
      Booking.transaction do
        @user = find_or_build_user(customer_params)
        @user.save!

        @booking = @business.bookings.new(
          user: @user,
          service_id: booking_params[:service_id],
          date: booking_params[:date],
          time: booking_params[:time],
          status: "confirmed"
        )
        @booking.save!
      end

      redirect_to business_bookings_path, notice: "Booking added successfully."
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = "Could not create booking. Please check the details below."
      render :add_booking, status: :unprocessable_entity
    end
  end

  private

  def find_or_build_user(attrs)
    user = User.find_or_initialize_by(email: attrs[:email])
    user.first_name = attrs[:first_name] if attrs[:first_name].present?
    user.last_name  = attrs[:last_name]  if attrs[:last_name].present?

    if user.new_record?
      random_password = SecureRandom.hex(12)
      user.password = random_password
      user.password_confirmation = random_password
    end

    user
  end

  def booking_params
    params.require(:booking).permit(:service_id, :date, :time)
  end

  def customer_params
    params.require(:booking).permit(:first_name, :last_name, :email)
  end
end