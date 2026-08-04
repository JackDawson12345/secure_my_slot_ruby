class BusinessPortal::WebsiteSettingsController <
  BusinessPortal::BaseController

  before_action :set_business
  before_action :set_business_website

  def index
  end

  def update
    if @business_website.update(website_settings_params)
      redirect_to business_website_settings_path,
                  notice: "Website settings updated successfully."
    else
      flash.now[:alert] = "Please correct the errors below."
      render :index, status: :unprocessable_entity
    end
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

  def website_settings_params
    permitted = params
                  .require(:business_website)
                  .permit(
                    :colour,
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

  def default_website_content
    {
      hero: {
        title: "",
        sentence: "",
        info_boxes: Array.new(3) do
          {
            icon: "",
            title: ""
          }
        end
      },
      services: {
        title: "",
        sentence: ""
      },
      about_us: {
        title: "",
        paragraph: "",
        icon_boxes: Array.new(4) do
          {
            title: "",
            sentence: ""
          }
        end
      },
      visit: {
        title: "",
        sentence: ""
      }
    }
  end
end