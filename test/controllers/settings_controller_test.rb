require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get settings_url
    assert_redirected_to new_session_url
  end

  test "shows account, bookmarklet and data sections" do
    sign_in_as users(:one)

    get settings_url
    assert_response :success
    assert_select "h2", "Account"
    assert_select "h2", "Bookmarklet"
    assert_select "h2", "API access"
    assert_select "a[href=?]", export_bookmarks_path(format: :html)
  end

  test "offers token generation when no token exists" do
    users(:one).update!(api_token: nil)
    sign_in_as users(:one)

    get settings_url
    assert_select "form[action=?] button", api_token_path, text: "Generate API token"
  end
end

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "create generates a fresh token" do
    old_token = users(:one).api_token

    post api_token_url
    assert_redirected_to settings_url
    assert_not_equal old_token, users(:one).reload.api_token
    assert users(:one).api_token.present?
  end

  test "destroy revokes the token" do
    delete api_token_url
    assert_redirected_to settings_url
    assert_nil users(:one).reload.api_token
  end
end
