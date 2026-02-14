require "test_helper"

class Github::PrSubmitterTest < ActiveSupport::TestCase
  setup do
    @project = create(:project, github_repo: "rails/rails")
    @task = create(:documentation_task,
      project: @project,
      status: :submitted,
      method_signature: "ActiveRecord::Base#connection_pool",
      source_file_path: "activerecord/lib/active_record/base.rb",
      source_code: "def connection_pool\n  # impl\nend"
    )
    @version = create(:draft_version,
      documentation_task: @task,
      label: :a,
      winner: true,
      content: "Returns the connection pool."
    )
  end

  test "branch_name is properly slugified" do
    submitter = Github::PrSubmitter.new(@task)
    branch = submitter.send(:branch_name)
    assert_match(/\Adocstown\/add-docs-/, branch)
    assert_match(/#{@task.id}\z/, branch)
    refute_match(/[#:]/, branch)
  end

  test "pr_title includes method signature" do
    submitter = Github::PrSubmitter.new(@task)
    title = submitter.send(:pr_title)
    assert_includes title, @task.method_signature
  end

  test "pr_body mentions docstown and vote count" do
    3.times { create(:vote, documentation_task: @task, draft_version: @version) }
    submitter = Github::PrSubmitter.new(@task)
    body = submitter.send(:pr_body)
    assert_includes body, "DocsTown"
    assert_includes body, @task.source_file_path
  end

  test "commit_message includes method signature" do
    submitter = Github::PrSubmitter.new(@task)
    message = submitter.send(:commit_message)
    assert_includes message, @task.method_signature
  end

  test "upstream_repo delegates to project github_repo" do
    submitter = Github::PrSubmitter.new(@task)
    assert_equal "rails/rails", submitter.send(:upstream_repo)
  end

  test "fork_repo uses repo name from project" do
    project = create(:project, github_repo: "ruby/ruby", name: "Ruby")
    task = create(:documentation_task, project: project, status: :submitted)
    submitter = Github::PrSubmitter.new(task)
    submitter.define_singleton_method(:fork_owner) { "testuser" }
    assert_equal "testuser/ruby", submitter.send(:fork_repo)
  end
end
