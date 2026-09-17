require "test_helper"

class BusinessPortal::AgreementsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_portal_agreements_index_url
    assert_response :success
  end
end
