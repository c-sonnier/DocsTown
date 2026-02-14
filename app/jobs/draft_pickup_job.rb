class DraftPickupJob < ApplicationJob
  queue_as :default

  def perform
    tasks = DocumentationTask.drafting
      .left_joins(:draft_versions)
      .group(:id)
      .having("COUNT(draft_versions.id) < 3")
      .limit(10)

    tasks.each do |task|
      DraftGenerationJob.perform_later(task.id)
    end

    Rails.logger.info("DraftPickupJob: enqueued #{tasks.size} tasks for draft generation")
  end
end
