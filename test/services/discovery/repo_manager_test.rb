require "test_helper"

class Discovery::RepoManagerTest < ActiveSupport::TestCase
  test "local path is derived from github_repo" do
    project = build(:project, github_repo: "rails/rails")
    manager = Discovery::RepoManager.new(project)

    assert_not manager.cloned?
  end
end
