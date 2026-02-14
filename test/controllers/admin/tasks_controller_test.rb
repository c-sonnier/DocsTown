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

  test "approve transitions task and enqueues job" do
    sign_in(@maintainer)
    assert_enqueued_with(job: PrSubmissionJob) do
      post approve_admin_task_path(@task)
    end
    assert @task.reload.submitted?
    assert_redirected_to admin_task_path(@task)
  end

  test "approve requires maintainer" do
    post approve_admin_task_path(@task)
    assert_redirected_to root_path
    assert @task.reload.pending_review?
  end

  test "reject with note transitions task back to voting" do
    sign_in(@maintainer)
    post reject_admin_task_path(@task), params: { reviewer_note: "Needs more examples" }
    assert @task.reload.voting?
    assert_equal "Needs more examples", @task.reviewer_note
    assert_redirected_to admin_tasks_path
  end

  test "reject without note shows error" do
    sign_in(@maintainer)
    post reject_admin_task_path(@task), params: { reviewer_note: "" }
    assert @task.reload.pending_review?
    assert_redirected_to admin_task_path(@task)
  end

  test "reject requires maintainer" do
    post reject_admin_task_path(@task), params: { reviewer_note: "No" }
    assert_redirected_to root_path
    assert @task.reload.pending_review?
  end

end
