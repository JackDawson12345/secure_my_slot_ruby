require "test_helper"

class Business::ServicesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_services_index_url
    assert_response :success
  end
end
