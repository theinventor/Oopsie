module Api
  module V1
    class ProjectsController < BaseController
      before_action :require_user_key!, only: [ :create, :update, :disable, :enable ]
      before_action :set_admin_project, only: [ :update, :disable, :enable ]

      def show
        if @project
          render json: serialize_project(@project)
        elsif @user
          unresolved_count_sql = ActiveRecord::Base.sanitize_sql_array(
            [ "COUNT(CASE WHEN error_groups.status = ? THEN 1 END) AS unresolved_count_cache", ErrorGroup.statuses[:unresolved] ]
          )
          projects = Project.left_joins(:error_groups)
            .select("projects.*, COUNT(error_groups.id) AS error_groups_count_cache, #{unresolved_count_sql}")
            .group("projects.id")
            .order(:name)
          render json: { projects: projects.map { |p| serialize_project_from_query(p) } }
        end
      end

      def create
        name = project_params[:name].to_s.strip
        existing_projects = Project.where(name: name)

        if existing_projects.any?
          return render_existing_project_or_conflict(existing_projects)
        end

        project = Project.new(name: name)

        if project.save
          render json: { project: serialize_project(project, include_api_key: true), created: true }, status: :created
        else
          render_validation_errors(project)
        end
      end

      def update
        name = project_params[:name]

        unless name
          return render json: { error: "Unprocessable Entity", details: [ "Name can't be blank" ] }, status: :unprocessable_entity
        end

        name = name.to_s.strip
        duplicate = Project.where(name: name).where.not(id: @admin_project.id).first

        if duplicate
          return render json: {
            error: "Project name already exists",
            project: serialize_project(duplicate)
          }, status: :conflict
        end

        if @admin_project.update(name: name)
          render json: { project: serialize_project(@admin_project) }
        else
          render_validation_errors(@admin_project)
        end
      end

      def disable
        @admin_project.disable!
        render json: { project: serialize_project(@admin_project) }
      end

      def enable
        @admin_project.enable!
        render json: { project: serialize_project(@admin_project) }
      end

      private

      def set_admin_project
        @admin_project = Project.find_by(id: params[:id])
        render json: { error: "Project not found" }, status: :not_found unless @admin_project
      end

      def project_params
        source = params[:project].presence || params
        source.permit(:name)
      end

      def if_missing?
        ActiveModel::Type::Boolean.new.cast(params[:if_missing])
      end

      def render_existing_project_or_conflict(projects)
        if if_missing? && projects.one?
          return render json: {
            project: serialize_project(projects.first, include_api_key: true),
            created: false
          }, status: :ok
        end

        render json: {
          error: "Project name already exists",
          matching_project_ids: projects.pluck(:id)
        }, status: :conflict
      end

      def render_validation_errors(project)
        render json: {
          error: "Unprocessable Entity",
          details: project.errors.full_messages
        }, status: :unprocessable_entity
      end

      def serialize_project(project, include_api_key: false)
        {
          id: project.id,
          name: project.name,
          status: project.status,
          disabled_at: project.disabled_at&.iso8601,
          accepts_ingest: project.accepts_ingest?,
          error_groups_count: project.error_groups.count,
          unresolved_count: project.error_groups.unresolved.count,
          created_at: project.created_at.iso8601
        }.tap do |payload|
          payload[:api_key] = project.api_key if include_api_key
        end
      end

      def serialize_project_from_query(project)
        {
          id: project.id,
          name: project.name,
          status: project.status,
          disabled_at: project.disabled_at&.iso8601,
          accepts_ingest: project.accepts_ingest?,
          error_groups_count: project.error_groups_count_cache.to_i,
          unresolved_count: project.unresolved_count_cache.to_i,
          created_at: project.created_at.iso8601
        }
      end
    end
  end
end
