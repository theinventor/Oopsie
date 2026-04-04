class DashboardController < ApplicationController
  def index
    @projects = Project.left_joins(:error_groups)
      .where(error_groups: { status: [ :unresolved, nil ] })
      .select("projects.*, COUNT(error_groups.id) AS unresolved_count")
      .group("projects.id")
      .order("projects.name ASC")
  end
end
