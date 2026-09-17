class BusinessPortal::WebsiteSettingsController < BusinessPortal::BaseController

  before_action :set_business
  before_action :set_business_website


  def index
  end


  private


  def set_business
    @business = current_user.business
  end


  def set_business_website
    @business_website =
      @business.business_website ||
      @business.build_business_website(default_website_content)
  end


end