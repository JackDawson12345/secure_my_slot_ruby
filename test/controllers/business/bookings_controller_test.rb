require "test_helper"

class Business::BookingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_bookings_index_url
    assert_response :success
  end
end
