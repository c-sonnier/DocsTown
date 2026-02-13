require "test_helper"

class DraftVersionTest < ActiveSupport::TestCase
  test "valid draft version" do
    draft = build(:draft_version)
    assert draft.valid?
  end

  test "requires provider" do
    draft = build(:draft_version, provider: nil)
    assert_not draft.valid?
  end

  test "requires content" do
    draft = build(:draft_version, content: nil)
    assert_not draft.valid?
  end

  test "enforces unique label per task" do
    task = create(:documentation_task)
    create(:draft_version, documentation_task: task, label: :a)
    duplicate = build(:draft_version, documentation_task: task, label: :a)
    assert_not duplicate.valid?
  end

  test "label enum" do
    draft = build(:draft_version, label: :b)
    assert draft.b?
  end
end
