class PagesController < ApplicationController
  def landing
    @stats = Rails.cache.fetch("site_stats", expires_in: 1.hour) do
      counts = DocumentationTask.pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(*) FILTER (WHERE status IN (3, 4))"),
        Arel.sql("COUNT(*) FILTER (WHERE status = 4)")
      )
      {
        tasks_created: counts[0],
        votes_cast: Vote.count,
        prs_submitted: counts[1],
        prs_merged: counts[2]
      }
    end
  end
end
