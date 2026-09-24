require "test_helper"

class BusinessPortal::ProductsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_products_index_url
    assert_response :success
  end
end
