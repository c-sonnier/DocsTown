require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "12345",
      info: {
        nickname: "testuser",
        image: "https://avatars.githubusercontent.com/u/12345",
        email: "test@example.com"
      }
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "create signs in with GitHub and creates user" do
    assert_difference "User.count", 1 do
      get "/auth/github/callback"
    end

    user = User.last
    assert_equal "12345", user.github_uid
    assert_equal "testuser", user.github_username
    assert_redirected_to root_path
    assert_equal user.id, session[:user_id]
  end

  test "create finds existing user on subsequent login" do
    user = create(:user, github_uid: "12345", github_username: "oldname")

    assert_no_difference "User.count" do
      get "/auth/github/callback"
    end

    user.reload
    assert_equal "testuser", user.github_username
    assert_equal user.id, session[:user_id]
  end

  test "destroy clears session" do
    user = create(:user)
    post "/auth/github/callback"

    delete "/logout"
    assert_nil session[:user_id]
    assert_redirected_to root_path
  end

  test "failure redirects with error message" do
    get "/auth/failure", params: { message: "invalid_credentials" }
    assert_redirected_to root_path
    assert_equal "Authentication failed: Invalid credentials", flash[:alert]
  end
end
