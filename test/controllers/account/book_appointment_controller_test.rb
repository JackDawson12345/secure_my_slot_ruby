require "test_helper"

class Account::BookAppointmentControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get account_book_appointment_index_url
    assert_response :success
  end
end
