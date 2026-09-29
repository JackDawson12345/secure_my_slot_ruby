require "test_helper"

class BusinessAgent::SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_agent_settings_index_url
    assert_response :success
  end
end
