require "test_helper"

class BusinessPortal::WebsiteSettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_website_settings_index_url
    assert_response :success
  end
end
