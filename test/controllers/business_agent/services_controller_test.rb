require "test_helper"

class BusinessAgent::ServicesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_agent_services_index_url
    assert_response :success
  end

  test "should get show" do
    get business_agent_services_show_url
    assert_response :success
  end
end
