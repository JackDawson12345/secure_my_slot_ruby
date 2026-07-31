require "test_helper"

class Pages::BusinnesWebsiteControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get pages_businnes_website_home_url
    assert_response :success
  end
end
