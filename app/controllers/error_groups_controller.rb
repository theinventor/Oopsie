class ErrorGroupsController < ApplicationController
  before_action :set_project
  before_action :set_error_group

  def show
    @occurrences = @error_group.occurrences.order(occurred_at: :desc).limit(50)
    @latest = @occurrences.first
    @activity = @error_group.error_group_notes.recent.limit(25)
  end

  def resolve
    @error_group.transition_status!(:resolved, actor: Current.user, source: "web")
    redirect_to project_error_group_path(@project, @error_group), notice: "Marked as resolved."
  end

  def ignore
    @error_group.transition_status!(:ignored, actor: Current.user, source: "web")
    redirect_to project_error_group_path(@project, @error_group), notice: "Marked as ignored."
  end

  def unresolve
    @error_group.transition_status!(:unresolved, actor: Current.user, source: "web")
    redirect_to project_error_group_path(@project, @error_group), notice: "Reopened."
  end

  def update_workflow_state
    @error_group.set_workflow_state!(
      params.require(:workflow_state),
      actor: Current.user,
      source: "web",
      note: params[:note]
    )
    redirect_to project_error_group_path(@project, @error_group), notice: "Workflow state updated."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to project_error_group_path(@project, @error_group), alert: e.message
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_error_group
    @error_group = @project.error_groups.find(params[:id])
  end
end
