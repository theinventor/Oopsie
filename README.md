# Oopsie

Self-hosted exception tracking for solo and indie Rails developers. One app, one SQLite database, zero external dependencies.

Deploy Oopsie. Add one gem to your app. Never pay for error tracking again.

## What it does

- **Receives exceptions** via the ExceptionReporter webhook format
- **Groups them intelligently** by error class + stack frame (not just message)
- **Notifies you** via email or webhook when something new breaks
- **Tracks regressions** — resolved errors that come back get reopened automatically

## Quick Start

```bash
git clone https://github.com/theinventor/Oopsie.git
cd Oopsie
bin/setup --skip-server
```

This will:
1. Install dependencies
2. Create the SQLite database
3. Seed an admin user (credentials printed to stdout — save them)
4. Create a demo project with sample exceptions

Then start the server:

```bash
bin/dev
```

Visit [http://localhost:3000](http://localhost:3000) and log in with the credentials from setup.

## Stack

- Ruby 4.0.2 / Rails 8.1
- SQLite (WAL mode)
- Solid Queue (background jobs)
- Propshaft (assets)
- No Redis. No Postgres. No external services.

## Client Integration

Oopsie accepts the [ExceptionReporter](https://github.com/theinventor/exception_reporter) webhook payload. In your client app:

```ruby
ExceptionReporter.configure do |config|
  config.add_webhook(
    "https://your-oopsie-instance.com/api/v1/exceptions",
    headers: { "Authorization" => "Bearer #{ENV['OOPSIE_API_KEY']}" }
  )
end
```

## API

### POST /api/v1/exceptions

Report an exception. Requires a project API key.

**Headers:**

```
Authorization: Bearer <project_api_key>
Content-Type: application/json
```

**Payload:**

```json
{
  "notifier": "ExceptionReporter",
  "version": "1.0.0",
  "timestamp": "2026-04-04T14:23:45.892Z",
  "app": {
    "name": "MyApp",
    "environment": "production"
  },
  "error": {
    "class_name": "NoMethodError",
    "message": "undefined method 'downloads' for nil",
    "backtrace": [
      "app/controllers/designs_controller.rb:42:in 'show'",
      "actionpack (8.1.3) lib/action_controller/metal.rb:227:in 'dispatch'"
    ],
    "first_line": {
      "file": "app/controllers/designs_controller.rb",
      "line": 42,
      "method": "show"
    },
    "causes": [],
    "handled": false
  },
  "context": {
    "request": { "url": "/designs/1", "method": "GET" },
    "action": "DesignsController#show"
  },
  "server": {
    "hostname": "web-1",
    "pid": 12345,
    "ruby_version": "4.0.2",
    "rails_version": "8.1.3"
  }
}
```

**Response (201 Created):**

```json
{
  "id": 1,
  "group_id": 1,
  "is_new_group": true
}
```

**Error responses:**

| Status | Meaning |
|--------|---------|
| 401 | Invalid or missing API key |
| 422 | Malformed payload (missing `error` or `error.class_name`) |
| 429 | Rate limit exceeded (100 requests/minute/project) |

### curl Example

```bash
curl -X POST http://localhost:3000/api/v1/exceptions \
  -H 'Authorization: Bearer YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "error": {
      "class_name": "TestError",
      "message": "Hello from curl!",
      "backtrace": ["app/test.rb:1:in test"],
      "first_line": {"file": "app/test.rb", "line": 1, "method": "test"}
    },
    "app": {"environment": "development"}
  }'
```

## Configuration

All configuration is via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY_BASE` | *(dev auto)* | Required in production |
| `OOPSIE_HOST` | `oopsie.example.com` | Public hostname, used for links in notification emails |
| `OOPSIE_FROM_EMAIL` | `notifications@example.com` | From address for outbound notification emails |
| `POSTMARK_API_TOKEN` | — | Postmark server API token for outbound email |
| `OOPSIE_ADMIN_EMAIL` | `admin@example.com` | Initial admin email (used on first `db:seed`) |
| `OOPSIE_ADMIN_PASSWORD` | *(random)* | Initial admin password (printed on first run) |
| `OOPSIE_RETENTION_DAYS` | `90` | Days to keep occurrence data before cleanup |
| `OOPSIE_SKIP_DEMO` | — | Set to `1` to skip demo data in `db:seed` |

See `.env.example` for a starter template.

## Fingerprinting

Exceptions are grouped by a SHA256 fingerprint of:

```
error.class_name + error.first_line.file + error.first_line.method
```

Method name is used instead of line number because line numbers shift with every edit, creating false new groups. When `first_line` is missing, falls back to:

```
error.class_name + normalized(error.message)
```

Message normalization strips numbers, UUIDs, hex strings, and quoted strings before hashing.

## Notifications

Notifications fire when:
- A **new** error group appears
- A **resolved** error group receives a new occurrence (regression)

Notifications do **not** fire on repeat occurrences of known unresolved errors (no alert fatigue).

Channels:
- **Email** — ActionMailer with error details, backtrace, and link to Oopsie UI
- **Webhook** — POST JSON payload to any URL (Slack incoming webhooks, etc.)

Configure notification rules per project in Settings.

## Retention

Occurrences older than 90 days (configurable via `OOPSIE_RETENTION_DAYS`) are automatically deleted daily at 3am by a Solid Queue recurring job.

The `occurrences_count` on each error group is a **lifetime total** — it reflects how many times the error has occurred, even after old occurrence rows are pruned.

## Deploy

Oopsie is a standard Rails app. Deploy it anywhere you'd deploy Rails:

### Fly.io

```bash
fly launch
fly secrets set SECRET_KEY_BASE=$(bin/rails secret)
fly secrets set OOPSIE_ADMIN_EMAIL=you@example.com
fly secrets set OOPSIE_ADMIN_PASSWORD=your-secure-password
fly deploy
```

### Any VPS (Ubuntu)

```bash
# Install Ruby 4.0.2, bundler, and SQLite
git clone https://github.com/theinventor/Oopsie.git
cd Oopsie
bundle install --without development test
RAILS_ENV=production bin/rails db:prepare
RAILS_ENV=production bin/rails db:seed
RAILS_ENV=production bin/rails server -b 0.0.0.0
```

Run Solid Queue in a separate process or use `bin/dev` which starts both.

### Health Check

`GET /up` returns 200 when the app is healthy. Use for load balancer health checks.

## Development

```bash
bin/setup --skip-server  # Install deps, prepare DB, seed data
bin/dev                  # Start server + Solid Queue
bin/rails test           # Run test suite (91 tests)
bin/rails console        # Rails console
```

## License

MIT
