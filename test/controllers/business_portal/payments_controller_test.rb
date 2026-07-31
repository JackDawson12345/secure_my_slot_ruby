require "test_helper"

class BusinessPortal::PaymentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_payments_index_url
    assert_response :success
  end
end
