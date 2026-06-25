require "rack/cors"

default_exception_ingest_origins = [
  "https://nerf-spring-break.netlify.app"
]

exception_ingest_origins = ENV.fetch(
  "OOPSIE_EXCEPTION_INGEST_CORS_ORIGINS",
  default_exception_ingest_origins.join(",")
).split(",").map(&:strip).reject(&:blank?).uniq

if exception_ingest_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*exception_ingest_origins)

      resource "/api/v1/exceptions",
        headers: %w[Authorization Content-Type X-Project-Id],
        methods: %i[post options],
        credentials: false,
        max_age: 600
    end
  end
end
