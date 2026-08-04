require "test_helper"

class BusinessPortal::SubscriptionControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_subscription_index_url
    assert_response :success
  end
end
