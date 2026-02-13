require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = build(:user)
    assert user.valid?
  end

  test "requires github_uid" do
    user = build(:user, github_uid: nil)
    assert_not user.valid?
  end

  test "requires github_username" do
    user = build(:user, github_username: nil)
    assert_not user.valid?
  end

  test "enforces unique github_uid" do
    create(:user, github_uid: "123")
    duplicate = build(:user, github_uid: "123")
    assert_not duplicate.valid?
  end

  test "role enum" do
    user = build(:user, role: :maintainer)
    assert user.maintainer?
  end
end
