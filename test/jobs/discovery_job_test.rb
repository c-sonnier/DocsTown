require "test_helper"

class DiscoveryJobTest < ActiveSupport::TestCase
  setup do
    @project = create(:project, github_repo: "test/repo-#{SecureRandom.hex(4)}")
    @fixture_path = Rails.root.join("test", "fixtures", "files", "discovery")
  end

  test "bulk creates tasks from parsed methods and skips duplicates" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods

    # First run creates tasks
    records = methods.map do |method|
      {
        project_id: @project.id,
        status: DocumentationTask.statuses[:drafting],
        method_signature: method.signature,
        source_file_path: method.source_file_path,
        source_code: method.source_code,
        class_context: method.class_context,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    result = DocumentationTask.insert_all(records, unique_by: [ :project_id, :method_signature ])
    first_count = result.count

    assert first_count > 0

    # Second run creates no duplicates
    result2 = DocumentationTask.insert_all(records, unique_by: [ :project_id, :method_signature ])
    assert_equal 0, result2.count
  end

  test "idempotent — running twice does not create duplicate tasks" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods

    records = methods.map do |method|
      {
        project_id: @project.id,
        status: DocumentationTask.statuses[:drafting],
        method_signature: method.signature,
        source_file_path: method.source_file_path,
        source_code: method.source_code,
        class_context: method.class_context,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    DocumentationTask.insert_all(records, unique_by: [ :project_id, :method_signature ])
    count_after_first = DocumentationTask.where(project: @project).count

    DocumentationTask.insert_all(records, unique_by: [ :project_id, :method_signature ])
    count_after_second = DocumentationTask.where(project: @project).count

    assert_equal count_after_first, count_after_second
  end
end
