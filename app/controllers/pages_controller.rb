class PagesController < ApplicationController
  def landing
    @stats = DocumentationTask.site_stats
  end
end
