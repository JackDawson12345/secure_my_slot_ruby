require "test_helper"

class Api::V1::BusinessControllerTest < ActionDispatch::IntegrationTest
  test "should get reports" do
    get api_v1_business_reports_url
    assert_response :success
  end
end
