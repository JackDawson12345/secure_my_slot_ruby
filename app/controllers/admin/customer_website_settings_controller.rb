class Admin::CustomerWebsiteSettingsController < Admin::BaseController
  before_action :set_customer
  before_action :set_business
  before_action :set_website

  def edit
  end

  def update
    if @website.update(website_params)
      redirect_to admin_customer_path(
                    @customer,
                    tab: "website_settings"
                  ), notice: "Website settings were updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_customer
    @customer = User
                  .where(role: 1)
                  .find(params[:customer_id])
  end

  def set_business
    @business = @customer.business

    return if @business.present?

    redirect_to admin_customer_path(@customer),
                alert: "This customer does not have a business profile."
  end

  def set_website
    @website = @business.business_website ||
               @business.build_business_website
  end

  def website_params
    params.require(:business_website).permit(
      :hero,
      :services,
      :about_us,
      :visit,
      :colour
    )
  end
end