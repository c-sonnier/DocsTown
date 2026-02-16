require "test_helper"

class Admin::ApprovalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @maintainer = create(:user, :maintainer)
    @project = create(:project)
    @task = create(:documentation_task, project: @project, status: :pending_review)
    %i[a b c].each do |label|
      create(:draft_version, documentation_task: @task, label: label, provider: "claude",
             winner: label == :a)
    end
  end

  test "create transitions task and enqueues job" do
    sign_in(@maintainer)
    assert_enqueued_with(job: PrSubmissionJob) do
      post admin_task_approval_path(@task)
    end
    assert @task.reload.submitted?
    assert_redirected_to admin_task_path(@task)
  end

  test "create requires maintainer" do
    post admin_task_approval_path(@task)
    assert_redirected_to root_path
    assert @task.reload.pending_review?
  end
end
