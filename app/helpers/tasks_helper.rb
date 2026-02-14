module TasksHelper
  def vote_bar_color(label)
    { "a" => "var(--pg-accent)", "b" => "var(--pg-secondary)", "c" => "var(--pg-tertiary)" }[label]
  end

  def status_label(status)
    status.titleize
  end

  def vote_progress_percentage(task)
    return 0 if task.draft_versions.empty?
    total_votes = task.votes.size
    return 0 if total_votes.zero?
    ((total_votes.to_f / DocumentationTask::CONSENSUS_VOTE_THRESHOLD) * 100).clamp(0, 100).round
  end

  def vote_progress_color(task)
    progress = vote_progress_percentage(task)
    if progress >= 100
      "var(--pg-tertiary)"
    elsif progress >= 50
      "var(--pg-quaternary)"
    else
      "var(--pg-accent)"
    end
  end

  def version_label_class(label)
    "version-label-#{label}"
  end

  def vote_btn_class(label)
    "vote-btn-#{label}"
  end

  def filter_pill_link(label, status_value, current_status)
    active = current_status == status_value
    link_to label,
      tasks_path(status: status_value, sort: params[:sort]),
      class: "filter-pill #{active ? 'active' : ''}"
  end

  def sort_pill_link(label, sort_value, current_sort)
    active = current_sort == sort_value || (current_sort.blank? && sort_value == "newest")
    link_to label,
      tasks_path(status: params[:status], sort: sort_value),
      class: "filter-pill #{active ? 'active' : ''}"
  end
end
