class ErrorGroupsController < ApplicationController
  before_action :set_project
  before_action :set_error_group

  def show
    @occurrences = @error_group.occurrences.order(occurred_at: :desc).limit(50)
    @latest = @occurrences.first
  end

  def resolve
    @error_group.resolved!
    redirect_to project_error_group_path(@project, @error_group), notice: "Marked as resolved."
  end

  def ignore
    @error_group.ignored!
    redirect_to project_error_group_path(@project, @error_group), notice: "Marked as ignored."
  end

  def unresolve
    @error_group.unresolved!
    redirect_to project_error_group_path(@project, @error_group), notice: "Reopened."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_error_group
    @error_group = @project.error_groups.find(params[:id])
  end
end
