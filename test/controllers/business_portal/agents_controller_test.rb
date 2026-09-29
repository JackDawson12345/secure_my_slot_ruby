require "test_helper"

class BusinessPortal::AgentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_agents_index_url
    assert_response :success
  end
end
