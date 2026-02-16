class Admin::RejectionsController < ApplicationController
  before_action :require_maintainer
  before_action :set_task

  def create
    if params[:reviewer_note].blank?
      redirect_to admin_task_path(@task), alert: "Rejection note is required."
      return
    end

    @task.reject!(note: params[:reviewer_note])
    redirect_to admin_tasks_path, notice: "Task sent back to voting."
  end

  private
    def set_task
      @task = DocumentationTask.find(params[:task_id])
    end
end
