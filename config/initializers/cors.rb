require "rack/cors"

exception_ingest_cors_origins = ENV.fetch(
  "OOPSIE_EXCEPTION_INGEST_CORS_ORIGINS",
  "https://nerf-spring-break.netlify.app"
).split(",").map(&:strip).compact_blank

if exception_ingest_cors_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*exception_ingest_cors_origins)

      resource "/api/v1/exceptions",
        headers: %w[Authorization Content-Type X-Project-Id],
        methods: %i[post options],
        credentials: false,
        max_age: 600
    end
  end
end
