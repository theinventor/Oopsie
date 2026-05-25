module Api
  module V1
    class ErrorGroupNotesController < BaseController
      before_action :require_project!
      before_action :set_error_group

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: "Unprocessable Entity", details: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def create
        note = @error_group.add_note!(
          note_body,
          actor: audit_actor,
          source: audit_source
        )

        render json: { note: serialize_note(note), error_group: serialize_group(@error_group) }, status: :created
      end

      private

      def set_error_group
        @error_group = @project.error_groups.find_by(id: params[:error_group_id])
        render json: { error: "Error group not found" }, status: :not_found unless @error_group
      end

      def note_body
        params[:body].presence || params.dig(:error_group_note, :body)
      end

      def serialize_group(g)
        {
          id: g.id,
          status: g.status,
          workflow_state: g.workflow_state,
          workflow_state_changed_at: g.workflow_state_changed_at.iso8601
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
