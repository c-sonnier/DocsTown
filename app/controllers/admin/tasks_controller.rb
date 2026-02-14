class Admin::TasksController < ApplicationController
    before_action :require_maintainer
    before_action :set_task, only: %i[show approve reject]

    def index
      @tasks = DocumentationTask.pending_review
        .includes(:draft_versions, :votes)
        .newest
        .limit(100)
    end

    def show
      @winning_version = @task.winning_version
    end

    def approve
      @task.approve!
      PrSubmissionJob.perform_later(@task.id)
      redirect_to admin_task_path(@task), notice: "Approved! PR submission queued."
    end

    def reject
      reviewer_note = params[:reviewer_note]
      if reviewer_note.blank?
        redirect_to admin_task_path(@task), alert: "Rejection note is required."
        return
      end

      @task.reject!(note: reviewer_note)
      redirect_to admin_tasks_path, notice: "Task sent back to voting."
    end

    private

    def set_task
      @task = DocumentationTask.includes(draft_versions: :votes).find(params[:id])
    end
end
