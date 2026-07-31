require "test_helper"

class Account::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get account_dashboard_index_url
    assert_response :success
  end
end
