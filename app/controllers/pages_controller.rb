class PagesController < ApplicationController
  def landing
    @stats = Rails.cache.fetch("site_stats", expires_in: 1.hour) do
      {
        tasks_created: DocumentationTask.count,
        votes_cast: Vote.count,
        prs_submitted: DocumentationTask.submitted.or(DocumentationTask.merged).count,
        prs_merged: DocumentationTask.merged.count
      }
    end
  end
end
