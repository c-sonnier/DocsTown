require "test_helper"

class DraftGenerationJobTest < ActiveSupport::TestCase
  setup do
    @task = create(:documentation_task, status: :drafting)
    stub_all_providers_success
  end

  test "generates three drafts and transitions to voting" do
    DraftGenerationJob.perform_now(@task.id)

    @task.reload
    assert_equal 3, @task.draft_versions.count
    assert @task.voting?
    assert_equal %w[a b c], @task.draft_versions.order(:label).map(&:label)
  end

  test "transitions to voting with 2 of 3 drafts on partial failure" do
    # Fail one provider
    stub_request(:post, KimiClient::API_URL)
      .to_return(status: 500, body: { error: { message: "Server error" } }.to_json)

    DraftGenerationJob.perform_now(@task.id)

    @task.reload
    assert_equal 2, @task.draft_versions.count
    assert @task.voting?
  end

  test "stays in drafting with fewer than 2 drafts" do
    # Fail two providers
    stub_request(:post, OpenaiClient::API_URL)
      .to_return(status: 500, body: { error: { message: "Server error" } }.to_json)
    stub_request(:post, KimiClient::API_URL)
      .to_return(status: 500, body: { error: { message: "Server error" } }.to_json)

    DraftGenerationJob.perform_now(@task.id)

    @task.reload
    assert_equal 1, @task.draft_versions.count
    assert @task.drafting?
  end

  test "skips tasks not in drafting status" do
    @task.update!(status: :voting)
    DraftGenerationJob.perform_now(@task.id)
    assert_equal 0, @task.draft_versions.count
  end

  test "skips tasks that already have drafts" do
    create(:draft_version, documentation_task: @task, label: :a)
    DraftGenerationJob.perform_now(@task.id)
    assert_equal 1, @task.draft_versions.count
  end

  test "each draft stores the prompt used" do
    DraftGenerationJob.perform_now(@task.id)

    @task.draft_versions.each do |draft|
      assert_not_nil draft.prompt_used
      assert_includes draft.prompt_used, @task.method_signature
    end
  end

  test "label assignment uses all three labels" do
    DraftGenerationJob.perform_now(@task.id)

    labels = @task.draft_versions.pluck(:label).sort
    assert_equal %w[a b c], labels
  end

  private

  def stub_all_providers_success
    stub_request(:post, ClaudeClient::API_URL)
      .to_return(
        status: 200,
        body: { content: [ { text: "Claude documentation" } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:post, OpenaiClient::API_URL)
      .to_return(
        status: 200,
        body: { choices: [ { message: { content: "OpenAI documentation" } } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:post, KimiClient::API_URL)
      .to_return(
        status: 200,
        body: { choices: [ { message: { content: "Kimi documentation" } } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
