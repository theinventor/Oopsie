# Oopsie Implementation Plan

Based on the approved design doc at `~/.gstack/projects/theinventor-Oopsie/troy-main-design-20260403-200858.md`.

## Phase 1: Foundation (Data Layer)
- [x] Create fix_plan.md
- [x] **Task 1: Generate core models and migrations** — Project, ErrorGroup, Occurrence, NotificationRule with proper indexes, validations, associations, and enums
- [x] **Task 2: Add Rails 8.1 built-in authentication** — User/Session models, login/logout, password reset, single admin user via db:seed. Root route → dashboard#index.

## Phase 2: API
- [x] **Task 3: Build POST /api/v1/exceptions endpoint** — fingerprinting, grouping, rate limiting (100/min/project), Bearer token auth, regression detection (resolved→unresolved). 9 integration tests.
- [x] **Task 4: Add API error handling** — 422 for missing error object or error.class_name, rescue_from for ActiveRecord validation failures. 4 new tests.

## Phase 3: Web UI
- [x] **Task 5: Dashboard + Projects CRUD** — project list with unresolved counts, create/edit/delete projects, project detail with error group table, app-wide layout with nav, CSS styling. 12 new tests.
- [x] **Task 6: Project view** — error groups sorted by last_seen_at with clickable links to detail (completed as part of Task 5, links added in Task 7)
- [x] **Task 7: Error group detail** — backtrace viewer, occurrence timeline table, resolve/ignore/unresolve buttons, context/server JSON display, stats bar. 9 new tests.
- [x] **Task 8: Settings page** — project API key display with Bearer header example, notification rule CRUD (email/webhook), enable/disable toggle. 10 new tests.

## Phase 4: Notifications & Background Jobs
- [x] **Task 9: Notification system** — OopsieMailer (HTML+text), NotifyJob dispatches to email/webhook rules, WebhookDeliveryJob with retry, API enqueues on new group/regression. 10 new tests.
- [x] **Task 10: Retention job** — RetentionCleanupJob deletes occurrences older than OOPSIE_RETENTION_DAYS (default 90), uses delete_all to preserve lifetime counter, runs daily at 3am via Solid Queue recurring schedule. 4 new tests.

## Phase 5: Polish
- [ ] Task 11: Seed data and bin/setup improvements
- [ ] Task 12: README with deploy instructions, API docs, curl examples
- [ ] Task 13: ExceptionReporter payload spec docs

## Notes
- SQLite in WAL mode (Rails 8.1 default)
- Rate limiting via Rails.cache memory_store (not Solid Cache)
- Fingerprint: SHA256 of error_class + first_line_file + first_line_method
- Occurrences_count is lifetime total (not affected by retention sweep)
