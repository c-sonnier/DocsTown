class PrStatusCheckJob < ApplicationJob
  queue_as :default

  def perform(task_id = nil)
    if task_id
      process_task(task_id)
    else
      tasks = DocumentationTask.submitted.where(pr_status: :open).where.not(pr_url: nil)
      tasks.find_each do |task|
        PrStatusCheckJob.perform_later(task.id)
      end
    end
  end

  private

  def process_task(task_id)
    task = DocumentationTask.find(task_id)
    check_pr_status(task)
  rescue Octokit::Error, Faraday::Error => e
    Rails.logger.error("PrStatusCheckJob: failed to check task #{task_id}: #{e.message}")
  end

  def check_pr_status(task)
    pr_number = extract_pr_number(task.pr_url)
    return unless pr_number

    pr = client.pull_request(task.project.github_repo, pr_number)

    case pr.state
    when "closed"
      if pr.merged
        task.mark_merged!
        Rails.logger.info("PrStatusCheckJob: task #{task.id} PR merged")
      else
        task.update!(pr_status: :closed)
        Rails.logger.info("PrStatusCheckJob: task #{task.id} PR closed without merge")
      end
    end
  end

  def extract_pr_number(url)
    url&.match(%r{/pull/(\d+)})&.captures&.first&.to_i
  end

  def client
    @client ||= Github.client
  end
end
