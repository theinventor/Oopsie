class DashboardController < ApplicationController
  def index
    unresolved_count_sql = ActiveRecord::Base.sanitize_sql_array(
      [ "COUNT(CASE WHEN error_groups.status = ? THEN 1 END) AS unresolved_count", ErrorGroup.statuses[:unresolved] ]
    )
    @projects = Project.left_joins(:error_groups)
      .select("projects.*, #{unresolved_count_sql}")
      .group("projects.id")
      .order("projects.name ASC")
  end
end
