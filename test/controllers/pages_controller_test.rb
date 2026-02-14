require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "landing page renders for unauthenticated users" do
    get root_path
    assert_response :success
    assert_includes response.body, "It takes a town to raise great docs."
    assert_includes response.body, "Sign in with GitHub"
  end

  test "landing page shows cached stats" do
    project = create(:project)
    create(:documentation_task, project: project, status: :voting)

    get root_path
    assert_response :success
    assert_includes response.body, "1" # tasks_created
  end

  test "authenticated users are redirected to dashboard" do
    user = create(:user)
    sign_in(user)

    get root_path
    assert_response :success
    assert_includes response.body, "Welcome back"
    assert_includes response.body, user.github_username
  end

end
