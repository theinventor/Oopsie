class DashboardController < ApplicationController
  def index
    @projects = Project.left_joins(:error_groups)
      .select("projects.*, COUNT(CASE WHEN error_groups.status = #{ErrorGroup.statuses[:unresolved]} THEN 1 END) AS unresolved_count")
      .group("projects.id")
      .order("projects.name ASC")
  end
end
