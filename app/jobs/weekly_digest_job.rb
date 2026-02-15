class WeeklyDigestJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100

  def perform
    stats = DocumentationTask.weekly_stats
    User.where(digest_opted_in: true)
        .where.not(email: [ nil, "" ])
        .where("last_digest_sent_at IS NULL OR last_digest_sent_at < ?", 6.days.ago)
        .find_each(batch_size: BATCH_SIZE) do |user|
      message = DigestMailer.weekly_digest(user, stats)
      if message.is_a?(ActionMailer::MessageDelivery)
        message.deliver_later
        user.update_column(:last_digest_sent_at, Time.current)
      end
    end
  end
end
