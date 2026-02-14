require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @project = create(:project)
    @voting_task = create(:documentation_task, project: @project, status: :voting)
    @drafting_task = create(:documentation_task, project: @project, status: :drafting)
    @merged_task = create(:documentation_task, project: @project, status: :merged)

    %i[a b c].each do |label|
      create(:draft_version, documentation_task: @voting_task, label: label, provider: "claude")
    end
  end

  test "index defaults to voting tasks" do
    get tasks_path
    assert_response :success
    assert_includes response.body, @voting_task.method_signature
    assert_not_includes response.body, @drafting_task.method_signature
    assert_not_includes response.body, @merged_task.method_signature
  end

  test "index filters by status" do
    get tasks_path(status: "merged")
    assert_response :success
    assert_includes response.body, @merged_task.method_signature
    assert_not_includes response.body, @voting_task.method_signature
  end

  test "index shows all when status is all" do
    get tasks_path(status: "all")
    assert_response :success
    assert_includes response.body, @voting_task.method_signature
    assert_includes response.body, @merged_task.method_signature
  end

  test "index sorts by newest by default" do
    get tasks_path(status: "all")
    assert_response :success
  end

  test "index sorts by most votes" do
    get tasks_path(status: "all", sort: "most_votes")
    assert_response :success
  end

  test "show displays task details" do
    get task_path(@voting_task)
    assert_response :success
    assert_includes response.body, @voting_task.method_signature
    assert_includes response.body, @voting_task.source_file_path
  end

  test "show displays draft versions" do
    get task_path(@voting_task)
    assert_response :success
    assert_includes response.body, "Version A"
    assert_includes response.body, "Version B"
    assert_includes response.body, "Version C"
  end

  test "show displays vote buttons for signed-in user when task is voting" do
    sign_in(@user)
    get task_path(@voting_task)
    assert_response :success
    assert_includes response.body, "Vote for Version A"
  end

  test "show shows sign-in prompt for anonymous user" do
    get task_path(@voting_task)
    assert_response :success
    assert_includes response.body, "Sign in to vote"
  end

  test "show hides vote buttons when task is not voting" do
    %i[a b c].each do |label|
      create(:draft_version, documentation_task: @merged_task, label: label, provider: "claude")
    end
    get task_path(@merged_task)
    assert_response :success
    assert_not_includes response.body, "Vote for Version"
  end

  test "index with most_votes sort and pagination does not crash" do
    30.times do
      task = create(:documentation_task, project: @project, status: :voting)
      create(:draft_version, documentation_task: task, label: :a, provider: "claude")
    end

    get tasks_path(sort: "most_votes", status: "all")
    assert_response :success
    assert_includes response.body, "Page"
  end

  test "index with invalid status param shows all tasks" do
    get tasks_path(status: "invalid_status")
    assert_response :success
    assert_includes response.body, @voting_task.method_signature
  end

end
