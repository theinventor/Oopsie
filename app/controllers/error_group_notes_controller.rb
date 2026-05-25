class ErrorGroupNotesController < ApplicationController
  before_action :set_project
  before_action :set_error_group

  def create
    @error_group.add_note!(
      note_params.fetch(:body),
      actor: Current.user,
      source: "web"
    )
    redirect_to project_error_group_path(@project, @error_group), notice: "Note added."
  rescue ActiveRecord::RecordInvalid, KeyError => e
    redirect_to project_error_group_path(@project, @error_group), alert: e.message
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_error_group
    @error_group = @project.error_groups.find(params[:error_group_id])
  end

  def note_params
    params.require(:error_group_note).permit(:body)
  end
end
