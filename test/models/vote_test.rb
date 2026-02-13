require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "valid vote" do
    task = create(:documentation_task)
    draft = create(:draft_version, documentation_task: task)
    vote = build(:vote, documentation_task: task, draft_version: draft)
    assert vote.valid?
  end

  test "enforces one vote per user per task" do
    task = create(:documentation_task)
    draft = create(:draft_version, documentation_task: task)
    user = create(:user)
    create(:vote, user: user, documentation_task: task, draft_version: draft)
    duplicate = build(:vote, user: user, documentation_task: task, draft_version: draft)
    assert_not duplicate.valid?
  end
end
