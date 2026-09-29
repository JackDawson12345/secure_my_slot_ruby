class BusinessPortal::ServiceCouponsController < BusinessPortal::BaseController

  before_action :set_service_coupon, only: [:show, :edit, :update, :destroy]
  before_action :set_services, only: [:new, :create, :edit, :update, :show]
  before_action :check_service_coupon_access,
                only: %i[
                new
                create
                edit
                update
                destroy
              ]


  def index
    @service_coupons = current_user.business.service_coupons.order(created_at: :desc)
  end


  def show

  end


  def new
    @service_coupon = current_user.business.service_coupons.new
  end


  def create
    @service_coupon = current_user.business.service_coupons.new(service_coupon_params)

    if @service_coupon.save
      redirect_to business_service_coupons_path,
                  notice: "Coupon created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end


  def edit

  end


  def update
    if @service_coupon.update(service_coupon_params)
      redirect_to business_service_coupons_path,
                  notice: "Coupon updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    @service_coupon.destroy

    redirect_to business_service_coupons_path,
                notice: "Coupon deleted successfully."
  end


  private


  def set_service_coupon
    @service_coupon = current_user.business.service_coupons.find(params[:id])
  end


  def set_services
    @services = current_user.business.services
  end


  def service_coupon_params
    params.require(:service_coupon).permit(
      :name,
      :code,
      :coupon_type,
      :discount,
      :active,
      :expires_at,
      services: []
    )
  end

  def check_service_coupon_access
    return if current_user.business.feature_enabled?(:service_coupons)

    redirect_to business_service_coupons_path,
                alert: "Upgrade to Pro to use service coupons."
  end

end