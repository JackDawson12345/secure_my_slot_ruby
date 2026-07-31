class BookingsController < ApplicationController

  def slots

    business = Business.find(params[:business_id])
    service = business.services.find(params[:service_id])
    date = Date.parse(params[:date])

    slots = BookingAvailability.new(
      business,
      service,
      date
    ).call

    render json: slots
  end


  def create

    byebug

    service = Service.find(params[:booking][:service_id])

    business = service.business


    user = User.find_or_initialize_by(
      email: params[:booking][:email]
    )


    if user.new_record?

      user.assign_attributes(
        first_name: params[:booking][:first_name],
        last_name: params[:booking][:last_name],
        phone_number: params[:booking][:phone_number],
        password: SecureRandom.hex(8)
      )

      user.save!

    end



    booking = Booking.new(
      user: user,
      business: business,
      service: service,
      date: params[:booking][:date],
      time: params[:booking][:time],
      status: "pending"
    )



    if booking.save

      redirect_to root_path,
                  notice: "Your booking has been requested."

    else

      redirect_back(
        fallback_location: root_path,
        alert: booking.errors.full_messages.join(", ")
      )

    end

  end

  private

  def booking_params

    params.require(:booking).permit(
      :service_id,
      :date,
      :time,
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :notes
    )

  end

end