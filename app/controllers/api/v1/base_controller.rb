module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_project!
      before_action :check_rate_limit!

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
          return
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
