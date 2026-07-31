require "test_helper"

class Business::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_dashboard_index_url
    assert_response :success
  end
end
