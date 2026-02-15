class TasksController < ApplicationController
  PER_PAGE = 25

  def index
    @tasks = DocumentationTask.includes(:draft_versions, :votes)
    @tasks = filter_by_status(@tasks)
    @tasks = sort_tasks(@tasks)

    @page = [ params[:page].to_i, 1 ].max
    @total_count = @tasks.except(:group, :order).count
    @total_pages = [ (@total_count.to_f / PER_PAGE).ceil, 1 ].max
    @tasks = @tasks.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
    @task = DocumentationTask.includes(draft_versions: :votes).find(params[:id])
    @current_vote = Current.user&.votes&.find_by(documentation_task: @task)
  end

  private

  def filter_by_status(tasks)
    return tasks if params[:status] == "all"
    status = params[:status].presence || "voting"
    DocumentationTask.statuses.key?(status) ? tasks.by_status(status) : tasks.by_status(:voting)
  end

  def sort_tasks(tasks)
    case params[:sort]
    when "most_votes"
      tasks.most_votes
    else
      tasks.newest
    end
  end
end
