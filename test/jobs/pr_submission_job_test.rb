require "test_helper"

class PrSubmissionJobTest < ActiveSupport::TestCase
  setup do
    @project = create(:project)
    @task = create(:documentation_task, project: @project, status: :submitted)
    create(:draft_version, documentation_task: @task, label: :a, winner: true)
  end

  test "skips task that is not submitted" do
    @task.update!(status: :voting)
    assert_nothing_raised do
      PrSubmissionJob.perform_now(@task.id)
    end
  end
end
