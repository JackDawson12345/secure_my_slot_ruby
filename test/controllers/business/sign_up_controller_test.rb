require "test_helper"

class Business::SignUpControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_sign_up_index_url
    assert_response :success
  end
end
