class VotesController < ApplicationController
  before_action :require_login
  before_action :set_task

  rescue_from DocumentationTask::InvalidTransition do
    redirect_to task_path(@task), alert: "Voting is not open for this task"
  end

  def create
    @task.cast_vote!(user: Current.user, draft_version_id: params[:draft_version_id])
    redirect_to task_path(@task)
  end

  def destroy
    @task.remove_vote!(user: Current.user)
    redirect_to task_path(@task)
  end

  private

  def set_task
    @task = DocumentationTask.find(params[:task_id])
  end
end
