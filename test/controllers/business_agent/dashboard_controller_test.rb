require "test_helper"

class BusinessAgent::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_agent_dashboard_index_url
    assert_response :success
  end
end
