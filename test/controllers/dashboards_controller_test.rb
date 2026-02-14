require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get root_path
    assert_response :success
    # Landing page, not dashboard
    assert_includes response.body, "It takes a town to raise great docs."
  end

  test "shows dashboard for authenticated user" do
    user = create(:user)
    sign_in(user)

    get authenticated_root_path
    assert_response :success
    assert_includes response.body, "Welcome back"
    assert_includes response.body, user.github_username
  end

  test "shows voting stats" do
    user = create(:user)
    project = create(:project)
    task = create(:documentation_task, project: project, status: :voting)
    version = create(:draft_version, documentation_task: task, label: :a, provider: "claude")
    create(:vote, user: user, documentation_task: task, draft_version: version)

    sign_in(user)
    get authenticated_root_path

    assert_response :success
    assert_includes response.body, "Votes Cast"
    assert_includes response.body, "1" # total votes
  end

  test "shows tasks needing votes" do
    user = create(:user)
    project = create(:project)
    task = create(:documentation_task, project: project, status: :voting)
    create(:draft_version, documentation_task: task, label: :a, provider: "claude")

    sign_in(user)
    get authenticated_root_path

    assert_response :success
    assert_includes response.body, "Tasks Needing Votes"
    assert_includes response.body, task.method_signature
  end

end
