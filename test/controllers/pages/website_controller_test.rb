require "test_helper"

class Pages::WebsiteControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get pages_website_home_url
    assert_response :success
  end
end
