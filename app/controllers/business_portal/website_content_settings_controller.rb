class BusinessPortal::WebsiteContentSettingsController <
  BusinessPortal::BaseController

  before_action :set_business_website


  def update
    unless current_user.business.feature_enabled?(:website_content)
      redirect_to business_website_settings_path,
                  alert: "Upgrade to Pro Plus to edit website content."
      return
    end

    settings = website_content_params

    if @business_website.update(settings)
      redirect_to business_website_settings_path,
                  notice: "Website content updated successfully."
    else
      flash.now[:alert] = "Please correct the errors below."

      render "business_portal/website_settings/index",
             status: :unprocessable_entity
    end
  end

  private

  def website_content_params
    permitted = params
                  .require(:business_website)
                  .permit(
                    :hero_image,
                    :about_image,
                    hero: [
                      :title,
                      :sentence,
                      {
                        info_boxes: {}
                      }
                    ],
                    services: [
                      :title,
                      :sentence
                    ],
                    about_us: [
                      :title,
                      :paragraph,
                      {
                        icon_boxes: {}
                      }
                    ],
                    visit: [
                      :title,
                      :sentence
                    ]
                  )
                  .to_h

    normalise_nested_boxes!(permitted)

    permitted
  end

  def normalise_nested_boxes!(permitted)
    hero_boxes = permitted.dig("hero", "info_boxes")

    if hero_boxes.is_a?(Hash)
      permitted["hero"]["info_boxes"] =
        hero_boxes
          .sort_by { |index, _values| index.to_i }
          .map(&:last)
    end

    about_boxes = permitted.dig("about_us", "icon_boxes")

    if about_boxes.is_a?(Hash)
      permitted["about_us"]["icon_boxes"] =
        about_boxes
          .sort_by { |index, _values| index.to_i }
          .map(&:last)
    end
  end

  def set_business_website
    @business_website = current_user.business.business_website
  end
end
