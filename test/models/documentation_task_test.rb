require "test_helper"

class DocumentationTaskTest < ActiveSupport::TestCase
  setup do
    @project = create(:project, github_repo: "rails/rails-#{SecureRandom.hex(4)}")
    @task = create(:documentation_task, project: @project)
  end

  test "valid task" do
    assert @task.valid?
  end

  test "requires method_signature" do
    task = build(:documentation_task, method_signature: nil)
    assert_not task.valid?
  end

  test "requires source_file_path" do
    task = build(:documentation_task, source_file_path: nil)
    assert_not task.valid?
  end

  test "requires source_code" do
    task = build(:documentation_task, source_code: nil)
    assert_not task.valid?
  end

  test "enforces unique method_signature per project" do
    duplicate = build(:documentation_task, project: @project, method_signature: @task.method_signature)
    assert_not duplicate.valid?
  end

  test "status enum defaults to drafting" do
    assert @task.drafting?
  end

  # State transitions

  test "start_voting! transitions from drafting to voting" do
    @task.start_voting!
    assert @task.voting?
  end

  test "start_voting! raises on invalid state" do
    @task.update!(status: :voting)
    assert_raises(DocumentationTask::InvalidTransition) { @task.start_voting! }
  end

  test "approve! transitions from pending_review to submitted" do
    @task.update!(status: :pending_review)
    @task.approve!
    assert @task.submitted?
  end

  test "reject! transitions back to voting with note" do
    @task.update!(status: :pending_review)
    @task.reject!(note: "Needs more detail")
    assert @task.voting?
    assert_equal "Needs more detail", @task.reviewer_note
  end

  test "reject! clears winner flag so a different draft can win" do
    draft_a = create(:draft_version, documentation_task: @task, label: :a, winner: true, votes_count: 5)
    draft_b = create(:draft_version, documentation_task: @task, label: :b, votes_count: 15)
    @task.update!(status: :pending_review)

    @task.reject!(note: "Try again")
    assert_not draft_a.reload.winner

    @task.update!(status: :voting)
    draft_b.update!(votes_count: 25)
    create_list(:vote, 25, documentation_task: @task, draft_version: draft_b)

    assert_nothing_raised { @task.finalize_consensus! }
    assert draft_b.reload.winner
  end

  test "mark_merged! transitions from submitted to merged" do
    @task.update!(status: :submitted)
    @task.mark_merged!
    assert @task.merged?
    assert @task.pr_merged?
  end

  # Consensus logic

  test "consensus_reached? returns false with insufficient votes" do
    assert_not @task.consensus_reached?
  end

  test "leading_version returns draft with most votes" do
    draft_a = create(:draft_version, documentation_task: @task, label: :a, votes_count: 10)
    draft_b = create(:draft_version, documentation_task: @task, label: :b, votes_count: 5)
    assert_equal draft_a, @task.leading_version
  end

  test "winning_version returns draft marked as winner" do
    draft = create(:draft_version, documentation_task: @task, label: :a, winner: true)
    assert_equal draft, @task.winning_version
  end

  # Prompt building

  test "build_prompt includes method signature and source code" do
    prompt = @task.build_prompt
    assert_includes prompt, @task.method_signature
    assert_includes prompt, @task.source_code
  end
end
