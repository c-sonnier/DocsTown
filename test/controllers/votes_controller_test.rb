require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @project = create(:project)
    @task = create(:documentation_task, project: @project, status: :voting)
    @version_a = create(:draft_version, documentation_task: @task, label: :a, provider: "claude")
    @version_b = create(:draft_version, documentation_task: @task, label: :b, provider: "openai")
    @version_c = create(:draft_version, documentation_task: @task, label: :c, provider: "kimi")
  end

  test "create requires authentication" do
    post task_vote_path(@task), params: { draft_version_id: @version_a.id }
    assert_redirected_to root_path
  end

  test "create creates vote and increments counter" do
    sign_in(@user)

    assert_difference "Vote.count", 1 do
      post task_vote_path(@task), params: { draft_version_id: @version_a.id }
    end

    assert_redirected_to task_path(@task)
    assert_equal 1, @version_a.reload.votes_count
  end

  test "create changing vote updates counters on both versions" do
    sign_in(@user)

    post task_vote_path(@task), params: { draft_version_id: @version_a.id }
    assert_equal 1, @version_a.reload.votes_count

    assert_no_difference "Vote.count" do
      post task_vote_path(@task), params: { draft_version_id: @version_b.id }
    end

    assert_equal 0, @version_a.reload.votes_count
    assert_equal 1, @version_b.reload.votes_count
  end

  test "destroy removes vote and decrements counter" do
    sign_in(@user)

    post task_vote_path(@task), params: { draft_version_id: @version_a.id }
    assert_equal 1, @version_a.reload.votes_count

    assert_difference "Vote.count", -1 do
      delete task_vote_path(@task)
    end

    assert_redirected_to task_path(@task)
    assert_equal 0, @version_a.reload.votes_count
  end

  test "destroy requires authentication" do
    delete task_vote_path(@task)
    assert_redirected_to root_path
  end

  test "destroy rejects on non-voting task" do
    sign_in(@user)
    post task_vote_path(@task), params: { draft_version_id: @version_a.id }

    @task.update!(status: :pending_review)

    delete task_vote_path(@task)
    assert_redirected_to task_path(@task)
    assert_equal "Voting is not open for this task", flash[:alert]
  end

  test "create rejects vote on non-voting task" do
    sign_in(@user)
    @task.update!(status: :pending_review)

    post task_vote_path(@task), params: { draft_version_id: @version_a.id }
    assert_redirected_to task_path(@task)
    assert_equal "Voting is not open for this task", flash[:alert]
    assert_equal 0, Vote.count
  end

  test "create triggers consensus when threshold reached" do
    sign_in(@user)

    19.times do
      voter = create(:user)
      create(:vote, user: voter, documentation_task: @task, draft_version: @version_a)
    end
    @version_a.update_column(:votes_count, 19)

    post task_vote_path(@task), params: { draft_version_id: @version_a.id }

    @task.reload
    assert @task.pending_review?, "Task should be pending_review after consensus"
    assert @version_a.reload.winner?, "Version A should be marked as winner"
  end

  test "consensus not triggered below threshold" do
    sign_in(@user)

    5.times do
      voter = create(:user)
      create(:vote, user: voter, documentation_task: @task, draft_version: @version_a)
    end
    @version_a.update_column(:votes_count, 5)

    post task_vote_path(@task), params: { draft_version_id: @version_a.id }

    @task.reload
    assert @task.voting?, "Task should still be voting"
  end

  test "one vote per user per task constraint" do
    sign_in(@user)

    post task_vote_path(@task), params: { draft_version_id: @version_a.id }
    assert_equal 1, Vote.where(user: @user, documentation_task: @task).count

    post task_vote_path(@task), params: { draft_version_id: @version_b.id }
    assert_equal 1, Vote.where(user: @user, documentation_task: @task).count
  end

end
