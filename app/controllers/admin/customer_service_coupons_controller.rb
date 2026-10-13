
class Admin::CustomerServiceCouponsController < Admin::BaseController
  before_action :set_customer
  before_action :set_business
  before_action :set_coupon, only: %i[edit update destroy]
  before_action :set_services, only: %i[new create edit update]

  def new
    @coupon = @business.service_coupons.new(
      coupon_type: "percentage",
      active: true
    )
  end

  def create
    @coupon = @business.service_coupons.new(coupon_params)

    if @coupon.save
      redirect_to admin_customer_path(
                    @customer,
                    tab: "service_coupons"
                  ),
                  notice: "Service coupon was added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @coupon.update(coupon_params)
      redirect_to admin_customer_path(
                    @customer,
                    tab: "service_coupons"
                  ),
                  notice: "Service coupon was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coupon.destroy!

    redirect_to admin_customer_path(
                  @customer,
                  tab: "service_coupons"
                ),
                notice: "Service coupon was removed successfully.",
                status: :see_other
  end

  private

  def set_customer
    @customer = User
                  .where(role: :business)
                  .find(params[:customer_id])
  end

  def set_business
    @business = @customer.business

    return if @business.present?

    redirect_to admin_customer_path(@customer),
                alert: "This customer does not have a business profile."
  end

  def set_coupon
    @coupon = @business.service_coupons.find(params[:id])
  end

  def set_services
    @services = @business.services.order(:name)
  end

  def coupon_params
    permitted = params.require(:service_coupon).permit(
      :name,
      :code,
      :coupon_type,
      :discount,
      :active,
      :expires_at,
      services: []
    )

    permitted[:services] = Array(permitted[:services])
                             .reject(&:blank?)
                             .map(&:to_s) if permitted.key?(:services)

    permitted
  end
end
