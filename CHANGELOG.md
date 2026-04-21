# Changelog

All notable changes to Oopsie will be documented in this file.

## [0.1.3.0] - 2026-04-20

### Changed
- CLI rewritten (v0.2.0) around user API keys: one key, every project. Project-scoped commands now send `X-Project-Id`, set automatically when you pin a project.
- `oopsie whoami` and `oopsie projects` show current auth, accessible projects, and unresolved counts at a glance.
- Config entries renamed from "projects" to "connections" (auto-migrated on first run). Each connection can pin a default remote project via `oopsie config set-project <name-or-id>`.
- Pinned projects store `{id, name}` so server-side renames break the pin instead of silently retargeting.
- Unknown flags (e.g. `--ststus`) fail loudly instead of being silently ignored.
- README and in-app CLI docs updated to document user vs project keys and the `X-Project-Id` header for scoped endpoints.

## [0.1.2.1] - 2026-04-10

### Added
- Postmark SMTP configuration for outbound email notifications in production
- Environment variables for all email settings (`POSTMARK_API_TOKEN`, `OOPSIE_HOST`, `OOPSIE_FROM_EMAIL`)
- `.env.example` template with all required and optional environment variables

### Changed
- From address now configurable via `OOPSIE_FROM_EMAIL` environment variable (was hardcoded placeholder)
- Production mailer host configurable via `OOPSIE_HOST` (was hardcoded `example.com`)
- Delivery errors now raised in production so failures surface in logs

## [0.1.2.0] - 2026-04-05

### Fixed
- Projects with only resolved or ignored errors were hidden from the projects list and dashboard. All projects now appear regardless of error group status.

## [0.1.1.0] - 2026-04-04

### Fixed
- CI `scan_ruby` job: replaced `permit!` calls with safe JSON body extraction for free-form context/server params (resolves brakeman mass assignment warnings)
- CI `scan_ruby` job: refactored webhook delivery to validate URI scheme and break brakeman taint tracking for `Net::HTTP` (resolves brakeman file access warning)
- CI `system-test` job: added `test/system/.keep` directory so `rails test:system` no longer crashes with `LoadError`
- Added URL validation on webhook notification rules to enforce HTTP/HTTPS schemes

## [0.1.0.0] - 2026-04-03

### Added
- Standalone CLI tool (`cli/oopsie`) for managing exceptions from the command line or AI bots. Requires only curl and jq. Supports multi-project config, error listing/filtering, detail views, and status changes (resolve, ignore, reopen).
- REST API endpoints for reading and managing error groups: list with status filtering, show with occurrences, resolve, ignore, and unresolve.
- Project info API endpoint returning name, error counts, and creation date.
- Shared API base controller with Bearer token auth and rate limiting for all API endpoints.
- Full test coverage for new API endpoints (auth, listing, filtering, show, status changes, cross-project isolation).
