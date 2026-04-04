# Changelog

All notable changes to Oopsie will be documented in this file.

## [0.1.0.0] - 2026-04-03

### Added
- Standalone CLI tool (`cli/oopsie`) for managing exceptions from the command line or AI bots. Requires only curl and jq. Supports multi-project config, error listing/filtering, detail views, and status changes (resolve, ignore, reopen).
- REST API endpoints for reading and managing error groups: list with status filtering, show with occurrences, resolve, ignore, and unresolve.
- Project info API endpoint returning name, error counts, and creation date.
- Shared API base controller with Bearer token auth and rate limiting for all API endpoints.
- Full test coverage for new API endpoints (auth, listing, filtering, show, status changes, cross-project isolation).
