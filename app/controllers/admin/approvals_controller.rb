class Admin::ApprovalsController < ApplicationController
  before_action :require_maintainer
  before_action :set_task

  def create
    @task.approve!
    PrSubmissionJob.perform_later(@task.id)
    redirect_to admin_task_path(@task), notice: "Approved! PR submission queued."
  end

  private
    def set_task
      @task = DocumentationTask.find(params[:task_id])
    end
end
