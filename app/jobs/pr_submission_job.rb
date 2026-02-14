class PrSubmissionJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(documentation_task_id)
    task = DocumentationTask.find(documentation_task_id)
    return unless task.submitted?

    Github::PrSubmitter.new(task).call
    Rails.logger.info("PrSubmissionJob: PR submitted for task #{task.id}: #{task.pr_url}")
  rescue Github::DocInserter::MethodNotFound => e
    Rails.logger.error("PrSubmissionJob: #{e.message} for task #{documentation_task_id}")
    raise
  end
end
