require "test_helper"

class BusinessPortal::SocialMediaControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_social_media_index_url
    assert_response :success
  end
end
