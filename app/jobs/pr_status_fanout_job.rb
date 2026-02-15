class PrStatusFanoutJob < ApplicationJob
  queue_as :default

  def perform
    DocumentationTask.submitted.where(pr_status: :open).where.not(pr_url: nil).find_each do |task|
      PrStatusCheckJob.perform_later(task.id)
    end
  end
end
