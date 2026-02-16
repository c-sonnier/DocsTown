class Admin::TasksController < ApplicationController
  before_action :require_maintainer
  before_action :set_task, only: :show

  def index
    @tasks = DocumentationTask.pending_review
      .includes(:draft_versions, :votes)
      .newest
      .limit(100)
  end

  def show
    @winning_version = @task.winning_version
  end

  private
    def set_task
      @task = DocumentationTask.includes(draft_versions: :votes).find(params[:id])
    end
end
