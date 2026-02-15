class DigestMailer < ApplicationMailer
  def self.compute_weekly_stats
    one_week_ago = 1.week.ago
    {
      new_voting_tasks: DocumentationTask.voting.where("created_at >= ? OR updated_at >= ?", one_week_ago, one_week_ago).count,
      submitted_prs: DocumentationTask.submitted.where(updated_at: one_week_ago..).count,
      merged_prs: DocumentationTask.merged.where(updated_at: one_week_ago..).count
    }
  end

  def weekly_digest(user, stats)
    @user = user
    @stats = stats
    @voting_tasks = DocumentationTask.voting.newest.includes(:votes).limit(10)

    return if no_activity?

    @unsubscribe_token = unsubscribe_token_for(user)
    unsubscribe_url = unsubscribe_url(token: @unsubscribe_token)

    headers["X-List-Unsubscribe"] = "<#{unsubscribe_url}>"
    headers["X-List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    mail(
      to: user.email,
      subject: "DocsTown Weekly Digest — #{Date.current.strftime('%b %d, %Y')}"
    )
  end

  private

  def no_activity?
    @stats[:new_voting_tasks].zero? && @stats[:submitted_prs].zero? && @stats[:merged_prs].zero?
  end

  def unsubscribe_token_for(user)
    User.unsubscribe_verifier.generate(user.id, purpose: :unsubscribe, expires_in: 30.days)
  end
end
