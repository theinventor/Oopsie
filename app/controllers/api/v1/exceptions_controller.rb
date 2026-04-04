module Api
  module V1
    class ExceptionsController < ActionController::API
      before_action :authenticate_project!
      before_action :check_rate_limit!

      def create
        error = params[:error] || {}
        first_line = error[:first_line]&.permit(:file, :line, :method)&.to_h

        fingerprint = ErrorGroup.generate_fingerprint(
          error_class: error[:class_name],
          first_line: first_line,
          message: error[:message]
        )

        is_new_group = false
        was_resolved = false

        error_group = @project.error_groups.find_by(fingerprint: fingerprint)

        if error_group
          was_resolved = error_group.resolved?
          error_group.update!(
            last_seen_at: Time.current,
            message: error[:message].presence || error_group.message
          )
          error_group.update!(status: :unresolved) if was_resolved
        else
          is_new_group = true
          error_group = @project.error_groups.create!(
            fingerprint: fingerprint,
            error_class: error[:class_name],
            message: error[:message],
            status: :unresolved,
            first_seen_at: Time.current,
            last_seen_at: Time.current
          )
        end

        occurrence = error_group.occurrences.create!(
          message: error[:message],
          backtrace: error[:backtrace],
          first_line: first_line,
          causes: error[:causes],
          handled: error[:handled] || false,
          context: params[:context]&.permit!&.to_h,
          environment: params.dig(:app, :environment),
          server_info: params[:server]&.permit!&.to_h,
          occurred_at: params[:timestamp] || Time.current,
          notifier_version: params[:version]
        )

        render json: {
          id: occurrence.id,
          group_id: error_group.id,
          is_new_group: is_new_group
        }, status: :created
      end

      private

      def authenticate_project!
        token = request.headers["Authorization"]&.delete_prefix("Bearer ")

        unless token.present?
          render json: { error: "Invalid API key" }, status: :unauthorized
          return
        end

        @project = Project.find_by(api_key: token)

        unless @project
          render json: { error: "Invalid API key" }, status: :unauthorized
        end
      end

      def check_rate_limit!
        return unless @project

        cache_key = "rate_limit:#{@project.id}:#{Time.current.to_i / 60}"
        count = Rails.cache.increment(cache_key, 1, expires_in: 2.minutes) || 1

        if count > 100
          render json: { error: "Rate limit exceeded" }, status: :too_many_requests
        end
      end
    end
  end
end
