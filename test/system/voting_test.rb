require "application_system_test_case"

class VotingTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @project = create(:project)
    @task = create(:documentation_task, project: @project, status: :voting)
    @version_a = create(:draft_version, documentation_task: @task, label: :a, provider: "claude")
    @version_b = create(:draft_version, documentation_task: @task, label: :b, provider: "openai")
    @version_c = create(:draft_version, documentation_task: @task, label: :c, provider: "kimi")

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: @user.github_uid,
      info: {
        nickname: @user.github_username,
        image: @user.avatar_url,
        email: @user.email
      }
    )
  end

  test "user can browse tasks index and see voting tasks" do
    visit tasks_path
    assert_text @task.method_signature
    assert_text "Voting"
  end

  test "user can navigate to task detail from index" do
    visit tasks_path
    click_link href: task_path(@task)
    assert_text @task.method_signature
    assert_text "VERSION A"
    assert_text "VERSION B"
    assert_text "VERSION C"
  end

  test "signed in user can vote for a version" do
    sign_in

    visit task_path(@task)
    assert_text "Vote for Version A"

    click_button "Vote for Version A"

    assert_text "Voted for Version A"
    assert_text "Remove vote"
  end

  test "signed in user can remove their vote" do
    sign_in

    visit task_path(@task)
    click_button "Vote for Version A"
    assert_text "Voted for Version A"

    click_link "Remove vote"
    assert_text "Vote for Version A"
  end

  test "signed in user can change their vote" do
    sign_in

    visit task_path(@task)
    click_button "Vote for Version A"
    assert_text "Voted for Version A"

    visit task_path(@task)
    click_button "Vote for Version B"
    assert_text "Voted for Version B"
  end

  private

  def sign_in
    visit "/auth/github/callback"
  end
end
