module Api
  module V1
    class ProjectsController < BaseController
      def show
        if @project
          render json: serialize_project(@project)
        elsif @user
          projects = Project.left_joins(:error_groups)
            .select("projects.*, COUNT(error_groups.id) AS error_groups_count_cache, COUNT(CASE WHEN error_groups.status = #{ErrorGroup.statuses[:unresolved]} THEN 1 END) AS unresolved_count_cache")
            .group("projects.id")
            .order(:name)
          render json: { projects: projects.map { |p| serialize_project_from_query(p) } }
        end
      end

      private

      def serialize_project(project)
        {
          id: project.id,
          name: project.name,
          error_groups_count: project.error_groups.count,
          unresolved_count: project.error_groups.unresolved.count,
          created_at: project.created_at.iso8601
        }
      end

      def serialize_project_from_query(project)
        {
          id: project.id,
          name: project.name,
          error_groups_count: project.error_groups_count_cache.to_i,
          unresolved_count: project.unresolved_count_cache.to_i,
          created_at: project.created_at.iso8601
        }
      end
    end
  end
end
