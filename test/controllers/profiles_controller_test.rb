require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "test@example.com", digest_opted_in: true)
  end

  test "show requires login" do
    get profile_path
    assert_redirected_to root_path
  end

  test "show displays profile for signed-in user" do
    sign_in(@user)
    get profile_path
    assert_response :success
    assert_includes response.body, @user.github_username
    assert_includes response.body, @user.email
  end

  test "update changes email and digest preference" do
    sign_in(@user)
    patch profile_path, params: { user: { email: "new@example.com", digest_opted_in: false } }
    assert_redirected_to profile_path

    @user.reload
    assert_equal "new@example.com", @user.email
    assert_equal false, @user.digest_opted_in
  end

  test "update requires login" do
    patch profile_path, params: { user: { email: "hack@evil.com" } }
    assert_redirected_to root_path
  end

end
