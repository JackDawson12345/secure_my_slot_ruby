class BusinessPortal::WebsiteGallerySettingsController <
  BusinessPortal::BaseController


  before_action :set_business_website


  def update

    images = params[:business_website][:gallery_images]


    if images.present?

      if @business_website.gallery_images.count + images.count > 20

        redirect_to business_website_settings_path,
                    alert: "You can upload a maximum of 20 gallery images."

        return
      end


      @business_website.gallery_images.attach(images)

    end


    redirect_to business_website_settings_path,
                notice: "Gallery updated successfully."

  end



  def destroy

    image = @business_website.gallery_images.find(params[:id])

    image.purge


    redirect_to business_website_settings_path,
                notice: "Gallery image removed successfully."

  end



  private


  def set_business_website
    @business_website = current_user.business.business_website
  end

end