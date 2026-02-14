require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "test@example.com", digest_opted_in: true)
    @token = Rails.application.message_verifier("unsubscribe").generate(@user.id, purpose: :unsubscribe, expires_in: 30.days)
  end

  test "show renders confirmation page with valid token" do
    get unsubscribe_path(token: @token)
    assert_response :success
    assert_includes response.body, "Unsubscribe"
  end

  test "show redirects with invalid token" do
    get unsubscribe_path(token: "invalid-token")
    assert_redirected_to root_path
  end

  test "show does not opt out user (GET is safe)" do
    get unsubscribe_path(token: @token)
    assert @user.reload.digest_opted_in?
  end

  test "create opts out user with valid token" do
    post unsubscribe_path(token: @token)
    assert_not @user.reload.digest_opted_in?
  end

  test "create redirects with invalid token" do
    post unsubscribe_path(token: "bad-token")
    assert_redirected_to root_path
    assert @user.reload.digest_opted_in?
  end
end
