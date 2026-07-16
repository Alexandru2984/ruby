require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a valid email address" do
    user = User.new(email_address: "not-an-email", password: "s3curepass")
    assert_not user.valid?
    assert user.errors[:email_address].any?
  end

  test "requires unique email address regardless of case" do
    duplicate = User.new(email_address: users(:one).email_address.upcase, password: "s3curepass")
    assert_not duplicate.valid?
  end

  test "requires password of at least 8 characters" do
    user = User.new(email_address: "short@example.com", password: "1234567")
    assert_not user.valid?
    assert user.errors[:password].any?
  end
end
