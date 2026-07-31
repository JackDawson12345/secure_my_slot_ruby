# app/controllers/business_portal/bookings_controller.rb

class BusinessPortal::BookingsController < BusinessPortal::BaseController
  def index
    @bookings = Booking.where(business: current_user.business)
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