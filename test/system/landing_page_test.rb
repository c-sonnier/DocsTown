require "application_system_test_case"

class LandingPageTest < ApplicationSystemTestCase
  test "landing page displays hero section" do
    visit root_path
    assert_text "Docs are"
    assert_text "broken."
    assert_text "How It Works"
    assert_text "Sign in with GitHub"
  end

  test "authenticated user sees dashboard instead of landing" do
    user = create(:user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.github_uid,
      info: {
        nickname: user.github_username,
        image: user.avatar_url,
        email: user.email
      }
    )

    visit "/auth/github/callback"
    visit root_path

    assert_text "Welcome back"
    assert_text user.github_username
  end
end
