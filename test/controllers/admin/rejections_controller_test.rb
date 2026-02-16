require "test_helper"

class Admin::RejectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @maintainer = create(:user, :maintainer)
    @project = create(:project)
    @task = create(:documentation_task, project: @project, status: :pending_review)
    %i[a b c].each do |label|
      create(:draft_version, documentation_task: @task, label: label, provider: "claude",
             winner: label == :a)
    end
  end

  test "create with note transitions task back to voting" do
    sign_in(@maintainer)
    post admin_task_rejection_path(@task), params: { reviewer_note: "Needs more examples" }
    assert @task.reload.voting?
    assert_equal "Needs more examples", @task.reviewer_note
    assert_redirected_to admin_tasks_path
  end

  test "create without note shows error" do
    sign_in(@maintainer)
    post admin_task_rejection_path(@task), params: { reviewer_note: "" }
    assert @task.reload.pending_review?
    assert_redirected_to admin_task_path(@task)
  end

  test "create requires maintainer" do
    post admin_task_rejection_path(@task), params: { reviewer_note: "No" }
    assert_redirected_to root_path
    assert @task.reload.pending_review?
  end
end
