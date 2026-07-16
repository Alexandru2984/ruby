require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_registration_url
    assert_response :success
  end

  test "signed in user is redirected away from sign up" do
    sign_in_as users(:one)

    get new_registration_url
    assert_redirected_to root_url
  end

  test "creates account and signs in with valid details" do
    assert_difference("User.count") do
      post registration_url, params: { user: { email_address: "new@example.com", password: "s3curepass", password_confirmation: "s3curepass" } }
    end

    assert_redirected_to root_url
    assert cookies[:session_id].present?
  end

  test "rejects mismatched password confirmation" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "new@example.com", password: "s3curepass", password_confirmation: "different" } }
    end

    assert_response :unprocessable_entity
  end

  test "rejects short password" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "new@example.com", password: "short", password_confirmation: "short" } }
    end

    assert_response :unprocessable_entity
  end

  test "signups can be disabled via DISABLE_SIGNUPS" do
    ENV["DISABLE_SIGNUPS"] = "1"

    get new_registration_url
    assert_redirected_to new_session_url

    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "locked@example.com", password: "s3curepass", password_confirmation: "s3curepass" } }
    end
    assert_redirected_to new_session_url

    get new_session_url
    assert_select "a[href=?]", new_registration_path, count: 0
  ensure
    ENV.delete("DISABLE_SIGNUPS")
  end

  test "rejects duplicate email address" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: users(:one).email_address, password: "s3curepass", password_confirmation: "s3curepass" } }
    end

    assert_response :unprocessable_entity
  end
end
