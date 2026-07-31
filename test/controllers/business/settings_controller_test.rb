require "test_helper"

class Business::SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_settings_index_url
    assert_response :success
  end
end
