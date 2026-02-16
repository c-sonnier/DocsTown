class DashboardsController < ApplicationController
  before_action :require_login

  def show
    @votes = Current.user.votes
      .includes(:draft_version, documentation_task: :draft_versions)
      .order(created_at: :desc)
    @stats = Current.user.vote_stats
    @pending_review_count = DocumentationTask.pending_review.count
    @tasks_needing_votes = DocumentationTask.voting
      .where.not(id: Current.user.votes.select(:documentation_task_id))
      .includes(:votes)
      .limit(5)
  end
end
