require "test_helper"

class Business::CustomersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get business_customers_index_url
    assert_response :success
  end
end
