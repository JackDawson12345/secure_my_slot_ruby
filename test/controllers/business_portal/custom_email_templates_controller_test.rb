require "test_helper"

class BusinessPortal::CustomEmailTemplatesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_custom_email_templates_index_url
    assert_response :success
  end
end
