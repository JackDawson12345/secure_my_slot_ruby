require "test_helper"

class Account::BookingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get account_bookings_index_url
    assert_response :success
  end
end
