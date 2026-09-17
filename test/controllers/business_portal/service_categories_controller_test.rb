require "test_helper"

class BusinessPortal::ServiceCategoriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_service_categories_index_url
    assert_response :success
  end
end
