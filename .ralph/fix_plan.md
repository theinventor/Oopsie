# Oopsie — Build Plan

Based on approved design doc. Self-hosted exception tracker for solo/indie Rails devs.
Accepts ExceptionReporter webhook payloads, groups by fingerprint, notifies on new errors.

## Phase 1: Foundation

- [ ] Generate authentication with Rails 8.1 built-in auth generator
- [ ] Create Project model (name, api_key) with migration and indexes
- [ ] Create ErrorGroup model (project_id, fingerprint, error_class, message, status enum, occurrences_count, first_seen_at, last_seen_at) with indexes
- [ ] Create Occurrence model (error_group_id, message, backtrace:json, first_line:json, causes:json, handled:boolean, context:json, environment, server_info:json, occurred_at, notifier_version) with indexes
- [ ] Create NotificationRule model (project_id, channel enum, destination, enabled)
- [ ] Add model associations and validations
- [ ] Seed initial admin user in bin/setup (print credentials to stdout)

## Phase 2: API Endpoint

- [ ] Create Api::V1::ExceptionsController with POST create action
- [ ] Implement Bearer token authentication (match Authorization header to project api_key)
- [ ] Parse ExceptionReporter webhook payload format (notifier, version, timestamp, app, error, context, server)
- [ ] Implement fingerprinting: SHA256 of error_class + first_line.file + first_line.method (fall back to error_class + normalized_message when first_line is null)
- [ ] Find-or-create ErrorGroup by fingerprint, update last_seen_at and counter cache
- [ ] Reopen resolved ErrorGroups on new occurrence (set status back to unresolved)
- [ ] Implement rate limiting: 100/min per project using memory_store cache with fixed 1-minute window
- [ ] Return proper responses: 201 Created, 401 Unauthorized, 422 Unprocessable Entity, 429 Too Many Requests
- [ ] Write request tests for the API endpoint covering all response codes

## Phase 3: Web UI

- [ ] Create ProjectsController with CRUD actions (dashboard shows unresolved count per project)
- [ ] Create ErrorGroupsController (index filtered by project, show with occurrences)
- [ ] Create OccurrencesController (show individual occurrence detail)
- [ ] Implement resolve/ignore/unresolve actions on ErrorGroups
- [ ] Build dashboard view: list of projects with unresolved error count
- [ ] Build project view: list of error groups sorted by last_seen_at with status badges
- [ ] Build error group detail view: latest backtrace, occurrence timeline, context display, action buttons
- [ ] Build project settings view: API key display, notification rule management
- [ ] Add basic CSS styling (keep it simple, no framework needed)

## Phase 4: Notifications

- [ ] Create ExceptionNotificationJob (Solid Queue)
- [ ] Implement email notifications via ActionMailer (error class, message, backtrace, link to UI)
- [ ] Implement webhook notifications (POST JSON with error group details to configured URL)
- [ ] Trigger on new ErrorGroup creation
- [ ] Trigger on regression (resolved group receives new occurrence)
- [ ] Create NotificationRulesController for CRUD in project settings

## Phase 5: Operations

- [ ] Add retention job: Solid Queue recurring task to delete occurrences older than OOPSIE_RETENTION_DAYS (default 90)
- [ ] Configure cache_store as :memory_store for rate limiting
- [ ] Add SQLite WAL mode configuration
- [ ] Copy ExceptionReporter payload spec into docs/exception_reporter_webhook_payload.md
- [ ] Write README with deploy instructions, API docs, curl examples
- [ ] Update bin/setup to handle first-run admin user creation

## Completed
- [x] Project enabled for Ralph
- [x] Design doc approved (see ~/.gstack/projects/theinventor-Oopsie/troy-main-design-20260403-200858.md)

## Notes
- Accept ExceptionReporter v1.0.0 webhook payload format exactly as specified
- Fingerprint by error_class + file + method (NOT line number — line numbers shift with edits)
- occurrences_count is a lifetime total, not count of stored rows (retention uses raw SQL DELETE)
- No JSON subfield querying in v1 — context/server_info are display-only blobs
- Single admin user for v1 (Rails 8.1 built-in auth)
