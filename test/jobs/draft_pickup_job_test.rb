require "test_helper"

class DraftPickupJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueues draft generation for drafting tasks without drafts" do
    task = create(:documentation_task, status: :drafting)

    assert_enqueued_with(job: DraftGenerationJob, args: [ task.id ]) do
      DraftPickupJob.perform_now
    end
  end

  test "skips tasks that already have 3 drafts" do
    task = create(:documentation_task, status: :drafting)
    create(:draft_version, documentation_task: task, label: :a, provider: "claude")
    create(:draft_version, documentation_task: task, label: :b, provider: "openai")
    create(:draft_version, documentation_task: task, label: :c, provider: "kimi")

    assert_no_enqueued_jobs(only: DraftGenerationJob) do
      DraftPickupJob.perform_now
    end
  end

  test "enqueues tasks with fewer than 3 drafts" do
    task = create(:documentation_task, status: :drafting)
    create(:draft_version, documentation_task: task, label: :a, provider: "claude")

    assert_enqueued_with(job: DraftGenerationJob, args: [ task.id ]) do
      DraftPickupJob.perform_now
    end
  end

  test "skips tasks not in drafting status" do
    create(:documentation_task, status: :voting)

    assert_no_enqueued_jobs(only: DraftGenerationJob) do
      DraftPickupJob.perform_now
    end
  end
end
