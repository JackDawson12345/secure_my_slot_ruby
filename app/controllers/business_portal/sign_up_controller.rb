# app/controllers/business_portal/sign_up_controller.rb

class BusinessPortal::SignUpController < ApplicationController
  before_action :check_login,
                except: :check_page_address

  def index
    @user = User.new
    @business = Business.new
  end

  def create
    @user = User.new(user_params)
    @user.role = 1

    @business = @user.build_business(
      business_name: business_params[:business_name],
      page_address: business_params[:domain_name],
      category: business_params[:category],
      phone_number: business_params[:phone_number],
      address: business_address
    )

    ActiveRecord::Base.transaction do
      @user.save!
      @business.save!

      create_business_setting!
      create_business_website!
    end

    sign_in(@user)

    redirect_to business_dashboard_path,
                notice: "Your business account has been created."
  rescue ActiveRecord::RecordInvalid
    render :index, status: :unprocessable_entity
  end

  def check_page_address

    page_address = params[:page_address].to_s.parameterize

    available =
      page_address.present? &&
      !Business.where("LOWER(page_address) = ?", page_address.downcase).exists?

    render json: {
      available: available,
      page_address: page_address
    }
  end

  private

  def create_business_setting!
    @business.create_business_setting!(
      business_name: @business.business_name,
      business_category: @business.category,
      phone_number: @business.phone_number,
      business_email: @user.email,
      business_description: "",
      address_line_1: @business.address["line_1"],
      address_line_2: @business.address["line_2"],
      town_or_city: @business.address["city"],
      postcode: @business.address["postcode"],
      country: @business.address["country"],
      booking_page_live: false,
      automatically_confirm_bookings: false,
      allow_customer_cancellations: true,
      require_customer_phone_number: true,
      cancellation_notice_hours: 24,
      new_booking_notifications: true,
      cancellation_notifications: true,
      daily_appointment_summary: false
    )
  end

  def create_business_website!
    @business.create_business_website!(
      colour: "blue",
      hero: {
        title: "",
        sentence: "",
        info_boxes: [
          {
            icon: "",
            title: ""
          },
          {
            icon: "",
            title: ""
          },
          {
            icon: "",
            title: ""
          }
        ]
      },
      services: {
        title: "",
        sentence: ""
      },
      about_us: {
        title: "",
        paragraph: "",
        icon_boxes: [
          {
            title: "",
            sentence: ""
          },
          {
            title: "",
            sentence: ""
          },
          {
            title: "",
            sentence: ""
          },
          {
            title: "",
            sentence: ""
          }
        ]
      },
      visit: {
        title: "",
        sentence: ""
      }
    )
  end

  def business_address
    {
      line_1: business_params[:line_1],
      line_2: business_params[:line_2],
      city: business_params[:city],
      postcode: business_params[:postcode],
      country: business_params[:country]
    }
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :password,
      :password_confirmation
    )
  end

  def business_params
    params.require(:user)
          .require(:business_attributes)
          .permit(
            :business_name,
            :domain_name,
            :category,
            :phone_number,
            :line_1,
            :line_2,
            :city,
            :postcode,
            :country
          )
  end

  def check_login
    if user_signed_in?
      if current_user.role == 1
        redirect_to business_dashboard_path
      else
        redirect_to account_dashboard_path
      end
    end

  end
end