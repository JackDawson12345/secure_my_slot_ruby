require "test_helper"

class Business::OpeningHoursControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_opening_hours_index_url
    assert_response :success
  end
end
