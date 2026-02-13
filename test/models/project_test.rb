require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "valid project" do
    project = build(:project)
    assert project.valid?
  end

  test "requires name" do
    project = build(:project, name: nil)
    assert_not project.valid?
  end

  test "requires github_repo" do
    project = build(:project, github_repo: nil)
    assert_not project.valid?
  end

  test "enforces unique github_repo" do
    create(:project, github_repo: "rails/rails")
    duplicate = build(:project, github_repo: "rails/rails")
    assert_not duplicate.valid?
  end
end
