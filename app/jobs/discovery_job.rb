class DiscoveryJob < ApplicationJob
  queue_as :default

  def perform(project_id)
    project = Project.find(project_id)

    # Clone or update repo
    repo = Discovery::RepoManager.new(project)
    repo.sync!

    # Parse and find undocumented methods
    parser = Discovery::MethodParser.new(repo.repo_path)
    methods = parser.find_undocumented_methods

    # Bulk create tasks, skipping duplicates
    created_count = bulk_create_tasks(project, methods)

    # Update scan timestamp
    project.update!(last_scanned_at: Time.current)

    Rails.logger.info(
      "Discovery complete for #{project.github_repo}: " \
      "#{methods.size} undocumented methods found, " \
      "#{created_count} new tasks created, " \
      "HEAD: #{repo.head_sha}"
    )
  end

  private

  def bulk_create_tasks(project, methods)
    return 0 if methods.empty?

    records = methods.map do |method|
      {
        project_id: project.id,
        status: DocumentationTask.statuses[:drafting],
        method_signature: method.signature,
        source_file_path: method.source_file_path,
        source_code: method.source_code,
        class_context: method.class_context,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    # Process in batches to avoid huge SQL statements
    count = 0
    records.each_slice(500) do |batch|
      result = DocumentationTask.insert_all(batch, unique_by: [ :project_id, :method_signature ])
      count += result.count
    end
    count
  end
end
