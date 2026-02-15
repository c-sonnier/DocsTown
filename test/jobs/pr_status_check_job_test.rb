require "test_helper"

class PrStatusCheckJobTest < ActiveSupport::TestCase
  test "skips tasks without pr_url" do
    project = create(:project)
    task = create(:documentation_task, project: project, status: :submitted, pr_status: :open, pr_url: nil)
    assert_nothing_raised do
      PrStatusCheckJob.perform_now(task.id)
    end
    assert task.reload.submitted?
  end
end

class PrStatusFanoutJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "runs without error when no submitted tasks exist" do
    assert_nothing_raised do
      PrStatusFanoutJob.perform_now
    end
  end

  test "enqueues per-task jobs for open PRs" do
    project = create(:project)
    task = create(:documentation_task, project: project, status: :submitted, pr_status: :open, pr_url: "https://github.com/rails/rails/pull/123")

    assert_enqueued_with(job: PrStatusCheckJob, args: [task.id]) do
      PrStatusFanoutJob.perform_now
    end
  end
end
