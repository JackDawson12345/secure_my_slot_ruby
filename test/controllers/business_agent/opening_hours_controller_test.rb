require "test_helper"

class BusinessAgent::OpeningHoursControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_agent_opening_hours_index_url
    assert_response :success
  end
end
