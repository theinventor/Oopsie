module Api
  module V1
    class ErrorGroupsController < BaseController
      before_action :require_project!
      before_action :set_error_group, only: [ :show, :resolve, :ignore, :unresolve, :update_workflow_state ]

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: "Unprocessable Entity", details: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      rescue_from ArgumentError do |e|
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def index
        scope = @project.error_groups.by_last_seen

        if params[:status].present? && ErrorGroup.statuses.key?(params[:status])
          scope = scope.where(status: params[:status])
        end

        if params[:workflow_state].present?
          scope = scope.with_workflow_state(params[:workflow_state])
        end

        total = scope.count
        groups = scope.limit(params.fetch(:limit, 50).to_i.clamp(1, 100))
                      .offset(params.fetch(:offset, 0).to_i.clamp(0, 10000))

        render json: {
          error_groups: groups.map { |g| serialize_group(g) },
          total: total
        }
      end

      def show
        occurrences = @error_group.occurrences
                                  .order(occurred_at: :desc)
                                  .limit(params.fetch(:limit, 20).to_i.clamp(1, 50))

        render json: {
          error_group: serialize_group(@error_group),
          occurrences: occurrences.map { |o| serialize_occurrence(o) },
          activity: @error_group.error_group_notes.recent.limit(25).map { |n| serialize_note(n) }
        }
      end

      def resolve
        @error_group.transition_status!(:resolved, actor: audit_actor, source: audit_source, note: params[:note])
        render json: { error_group: serialize_group(@error_group) }
      end

      def ignore
        @error_group.transition_status!(:ignored, actor: audit_actor, source: audit_source, note: params[:note])
        render json: { error_group: serialize_group(@error_group) }
      end

      def unresolve
        @error_group.transition_status!(:unresolved, actor: audit_actor, source: audit_source, note: params[:note])
        render json: { error_group: serialize_group(@error_group) }
      end

      def update_workflow_state
        @error_group.set_workflow_state!(
          params.require(:workflow_state),
          actor: audit_actor,
          source: audit_source,
          note: params[:note]
        )
        render json: { error_group: serialize_group(@error_group) }
      end

      private

      def set_error_group
        @error_group = @project.error_groups.find_by(id: params[:id])
        render json: { error: "Error group not found" }, status: :not_found unless @error_group
      end

      def serialize_group(g)
        {
          id: g.id,
          error_class: g.error_class,
          message: g.message,
          status: g.status,
          workflow_state: g.workflow_state,
          workflow_state_changed_at: g.workflow_state_changed_at.iso8601,
          occurrences_count: g.occurrences_count,
          first_seen_at: g.first_seen_at.iso8601,
          last_seen_at: g.last_seen_at.iso8601
        }
      end

      def serialize_occurrence(o)
        {
          id: o.id,
          message: o.message,
          backtrace: o.backtrace,
          first_line: o.first_line,
          causes: o.causes,
          handled: o.handled,
          context: o.context,
          environment: o.environment,
          server_info: o.server_info,
          occurred_at: o.occurred_at.iso8601
        }
      end

      def serialize_note(note)
        {
          id: note.id,
          kind: note.kind,
          body: note.body,
          from_value: note.from_value,
          to_value: note.to_value,
          actor_kind: note.actor_kind,
          actor_label: note.actor_label,
          source: note.source,
          created_at: note.created_at.iso8601
        }
      end

      def audit_actor
        current_user || current_project || { kind: "api", label: "api" }
      end

      def audit_source
        request.headers["X-Oopsie-Client"].presence || "api"
      end
    end
  end
end
