require "test_helper"

class Account::BookingHistoryControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get account_booking_history_index_url
    assert_response :success
  end
end
