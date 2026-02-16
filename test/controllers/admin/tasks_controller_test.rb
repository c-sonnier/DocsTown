require "test_helper"

class Admin::TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @maintainer = create(:user, :maintainer)
    @voter = create(:user)
    @project = create(:project)
    @task = create(:documentation_task, project: @project, status: :pending_review)
    %i[a b c].each do |label|
      create(:draft_version, documentation_task: @task, label: label, provider: "claude",
             winner: label == :a)
    end
  end

  test "index requires maintainer" do
    get admin_tasks_path
    assert_redirected_to root_path
  end

  test "index rejects non-maintainer user" do
    sign_in(@voter)
    get admin_tasks_path
    assert_redirected_to root_path
  end

  test "index shows pending review tasks for maintainer" do
    sign_in(@maintainer)
    get admin_tasks_path
    assert_response :success
    assert_includes response.body, @task.method_signature
  end

  test "index does not show non-pending tasks" do
    voting_task = create(:documentation_task, project: @project, status: :voting)
    sign_in(@maintainer)
    get admin_tasks_path
    assert_response :success
    assert_not_includes response.body, voting_task.method_signature
  end

  test "show requires maintainer" do
    get admin_task_path(@task)
    assert_redirected_to root_path
  end

  test "show displays task details for maintainer" do
    sign_in(@maintainer)
    get admin_task_path(@task)
    assert_response :success
    assert_includes response.body, @task.method_signature
    assert_includes response.body, "Approve"
    assert_includes response.body, "Reject"
  end
end
