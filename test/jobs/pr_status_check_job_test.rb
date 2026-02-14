require "test_helper"

class PrStatusCheckJobTest < ActiveSupport::TestCase
  test "runs without error when no submitted tasks exist" do
    assert_nothing_raised do
      PrStatusCheckJob.perform_now
    end
  end

  test "skips tasks without pr_url" do
    project = create(:project)
    task = create(:documentation_task, project: project, status: :submitted, pr_status: :open, pr_url: nil)
    assert_nothing_raised do
      PrStatusCheckJob.perform_now
    end
    assert task.reload.submitted?
  end
end
