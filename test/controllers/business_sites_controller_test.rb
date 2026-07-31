require "test_helper"

class BusinessSitesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get business_sites_show_url
    assert_response :success
  end
end
