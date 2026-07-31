# app/controllers/business_portal/sign_up_controller.rb

class BusinessPortal::SignUpController < ApplicationController

  before_action :check_login
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
      address: {
        line_1: business_params[:line_1],
        line_2: business_params[:line_2],
        city: business_params[:city],
        postcode: business_params[:postcode],
        country: business_params[:country]
      }
    )

    ActiveRecord::Base.transaction do
      @user.save!
      @business.save!
    end

    sign_in(@user)

    redirect_to business_dashboard_path,
                notice: "Your business account has been created."
  rescue ActiveRecord::RecordInvalid
    render :index, status: :unprocessable_entity
  end

  private

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
    redirect_to '/' if user_signed_in?
  end
end