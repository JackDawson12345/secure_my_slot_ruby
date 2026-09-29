require "test_helper"

class BusinessAgent::BookingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_agent_bookings_index_url
    assert_response :success
  end
end
