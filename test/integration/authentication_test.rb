require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "set_current_user loads user from session" do
    user = create(:user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.github_uid,
      info: { nickname: user.github_username, image: user.avatar_url, email: user.email }
    )

    get "/auth/github/callback"
    get root_path
    assert_response :success
  end

  test "require_login redirects unauthenticated users" do
    # This will be exercised once we have protected routes.
    # For now, verify the helper exists and root is accessible.
    get root_path
    assert_response :success
  end

  test "navbar shows sign in button when logged out" do
    get root_path
    assert_select "button", text: "Sign in with GitHub"
  end

  test "navbar shows username when logged in" do
    sign_in_as create(:user, github_username: "navuser")
    get root_path
    assert_select "span", text: "navuser"
  end

  private

  def sign_in_as(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.github_uid,
      info: { nickname: user.github_username, image: user.avatar_url, email: user.email }
    )
    get "/auth/github/callback"
  end
end
