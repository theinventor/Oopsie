module Api
  module V1
    class ProjectsController < BaseController
      def show
        render json: {
          id: @project.id,
          name: @project.name,
          error_groups_count: @project.error_groups.count,
          unresolved_count: @project.error_groups.unresolved.count,
          created_at: @project.created_at.iso8601
        }
      end
    end
  end
end
