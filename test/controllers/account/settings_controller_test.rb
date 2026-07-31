require "test_helper"

class Account::SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get account_settings_index_url
    assert_response :success
  end
end
