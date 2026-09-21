require "test_helper"

class BusinessPortal::ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_reports_index_url
    assert_response :success
  end
end
