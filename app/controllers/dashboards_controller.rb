class DashboardsController < ApplicationController
  before_action :require_login

  def show
    @votes = Current.user.votes
      .includes(:draft_version, documentation_task: :draft_versions)
      .order(created_at: :desc)

    total = Current.user.votes.count
    winning = Current.user.votes.joins(:draft_version).where(draft_versions: { winner: true }).count
    rate = total > 0 ? (winning.to_f / total * 100).round : 0
    @stats = { total_votes: total, winning_picks: winning, win_rate: rate }

    @pending_review_count = DocumentationTask.pending_review.count
    @tasks_needing_votes = DocumentationTask.voting
      .where.not(id: Current.user.votes.select(:documentation_task_id))
      .includes(:votes)
      .limit(5)
  end
end
