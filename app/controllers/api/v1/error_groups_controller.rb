module Api
  module V1
    class ErrorGroupsController < BaseController
      before_action :set_error_group, only: [ :show, :resolve, :ignore, :unresolve ]

      def index
        scope = @project.error_groups.by_last_seen

        if params[:status].present? && ErrorGroup.statuses.key?(params[:status])
          scope = scope.where(status: params[:status])
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
          occurrences: occurrences.map { |o| serialize_occurrence(o) }
        }
      end

      def resolve
        @error_group.resolved!
        render json: { error_group: serialize_group(@error_group) }
      end

      def ignore
        @error_group.ignored!
        render json: { error_group: serialize_group(@error_group) }
      end

      def unresolve
        @error_group.unresolved!
        render json: { error_group: serialize_group(@error_group) }
      end

      private

      def set_error_group
        @error_group = @project.error_groups.find_by(id: params[:id])
        unless @error_group
          render json: { error: "Error group not found" }, status: :not_found
          return
        end
      end

      def serialize_group(g)
        {
          id: g.id,
          error_class: g.error_class,
          message: g.message,
          status: g.status,
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
    end
  end
end
