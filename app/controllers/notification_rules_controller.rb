class NotificationRulesController < ApplicationController
  before_action :set_project
  before_action :set_notification_rule, only: [ :edit, :update, :destroy, :toggle ]

  def create
    @notification_rule = @project.notification_rules.build(notification_rule_params)

    if @notification_rule.save
      redirect_to settings_project_path(@project), notice: "Notification rule created."
    else
      @notification_rules = @project.notification_rules.order(:created_at)
      render "projects/settings", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @notification_rule.update(notification_rule_params)
      redirect_to settings_project_path(@project), notice: "Notification rule updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notification_rule.destroy
    redirect_to settings_project_path(@project), notice: "Notification rule deleted."
  end

  def toggle
    @notification_rule.update!(enabled: !@notification_rule.enabled)
    redirect_to settings_project_path(@project),
      notice: "Rule #{@notification_rule.enabled? ? 'enabled' : 'disabled'}."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_notification_rule
    @notification_rule = @project.notification_rules.find(params[:id])
  end

  def notification_rule_params
    params.require(:notification_rule).permit(:channel, :destination)
  end
end
