class BusinessPortal::ServiceCategoriesController < BusinessPortal::BaseController

  before_action :set_service_category, only: [:edit, :update, :destroy]
  before_action :check_service_categories_access,
                only: %i[
                new
                create
                edit
                update
                destroy
              ]


  def index
    @service_categories = current_user.business.service_categories.order(:name)
  end


  def new
    @service_category = current_user.business.service_categories.new
  end


  def create
    @service_category = current_user.business.service_categories.new(service_category_params)

    if @service_category.save
      redirect_to business_service_categories_path,
                  notice: "Service category created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end


  def edit
  end


  def update
    if @service_category.update(service_category_params)
      redirect_to business_service_categories_path,
                  notice: "Service category updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    @service_category.destroy

    redirect_to business_service_categories_path,
                notice: "Service category removed successfully."
  end


  private


  def set_service_category
    @service_category = current_user.business.service_categories.find(params[:id])
  end


  def service_category_params
    params.require(:service_category).permit(:name)
  end

  def check_service_categories_access
    return if current_user.business.feature_enabled?(:service_categories)

    redirect_to business_service_categories_path,
                alert: "Upgrade to Pro to use service categories."
  end

end