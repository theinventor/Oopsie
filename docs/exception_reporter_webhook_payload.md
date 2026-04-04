# ExceptionReporter Webhook Payload Specification

**Version:** 1.0.0
**Format:** JSON
**Content-Type:** `application/json`

This document defines the webhook payload format sent by the [ExceptionReporter](https://github.com/theinventor/exception_reporter) gem. Oopsie accepts this format at `POST /api/v1/exceptions`.

## Full Payload Example

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
      "actionpack (8.1.3) lib/action_controller/metal/basic_implicit_render.rb:8:in 'process_action'",
      "actionpack (8.1.3) lib/action_controller/metal.rb:227:in 'dispatch'"
    ],
    "first_line": {
      "file": "app/controllers/designs_controller.rb",
      "line": 42,
      "method": "show"
    },
    "causes": [
      {
        "class_name": "ActiveRecord::RecordNotFound",
        "message": "Couldn't find Design with 'id'=999"
      }
    ],
    "handled": false
  },
  "context": {
    "request": {
      "url": "https://myapp.com/designs/999",
      "method": "GET",
      "ip": "192.168.1.1",
      "user_agent": "Mozilla/5.0..."
    },
    "user": {
      "id": 42,
      "email": "user@example.com"
    },
    "action": "DesignsController#show",
    "params": {
      "controller": "designs",
      "action": "show",
      "id": "999"
    }
  },
  "server": {
    "hostname": "web-1",
    "pid": 12345,
    "ruby_version": "4.0.2",
    "rails_version": "8.1.3"
  }
}
```

## Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `notifier` | string | No | Identifier for the reporting library. Always `"ExceptionReporter"`. |
| `version` | string | No | Payload schema version. Stored on Occurrence as `notifier_version`. |
| `timestamp` | string (ISO 8601) | No | When the exception occurred. Falls back to server time if missing. |
| `app` | object | No | Application metadata. |
| `error` | object | **Yes** | The exception data. |
| `context` | object | No | Variable-shape request/job/custom context. |
| `server` | object | No | Server environment information. |

## `app` Object

| Field | Type | Description |
|-------|------|-------------|
| `app.name` | string | Display name of the application. Not used for routing — the API key determines the project. |
| `app.environment` | string | Deployment environment (e.g., `"production"`, `"staging"`). Stored on each Occurrence for filtering. |

## `error` Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `error.class_name` | string | **Yes** | Exception class name (e.g., `"NoMethodError"`). Used for display and fingerprinting. |
| `error.message` | string | No | Human-readable error message. Stored on both ErrorGroup and Occurrence. |
| `error.backtrace` | array of strings | No | Stack trace frames, most recent first. Each string is `"file:line:in 'method'"`. |
| `error.first_line` | object | No | Parsed top stack frame. Drives fingerprinting. See below. |
| `error.causes` | array of objects | No | Exception cause chain (up to 10 deep). Each has `class_name` and `message`. |
| `error.handled` | boolean | No | `false` = unhandled crash, `true` = manually reported via `ExceptionReporter.notify`. Defaults to `false`. |

### `error.first_line` Object

The parsed top frame of the backtrace. When present, this drives fingerprinting (preferred over message-based grouping).

| Field | Type | Description |
|-------|------|-------------|
| `first_line.file` | string | Source file path (e.g., `"app/controllers/designs_controller.rb"`) |
| `first_line.line` | integer | Line number |
| `first_line.method` | string | Method name (e.g., `"show"`) |

**Fingerprinting uses `file` and `method` only** — not `line`, because line numbers shift with edits above the call site.

When `first_line` is absent or incomplete, Oopsie falls back to fingerprinting by `error.class_name` + normalized `error.message`.

### `error.causes` Array

Each cause object:

| Field | Type | Description |
|-------|------|-------------|
| `causes[].class_name` | string | Cause exception class |
| `causes[].message` | string | Cause exception message |

Causes capture the Ruby exception chain (`exception.cause`), up to 10 levels deep.

## `context` Object

Variable-shape metadata about what was happening when the exception occurred. Oopsie stores this as opaque JSON on each Occurrence — no fields are required or interpreted.

### Web Request Context

```json
{
  "context": {
    "request": {
      "url": "https://myapp.com/designs/999",
      "method": "GET",
      "ip": "192.168.1.1",
      "user_agent": "Mozilla/5.0..."
    },
    "user": {
      "id": 42,
      "email": "user@example.com"
    },
    "action": "DesignsController#show",
    "params": { "id": "999" }
  }
}
```

### Background Job Context

```json
{
  "context": {
    "job": {
      "class": "ProcessPaymentJob",
      "queue": "critical",
      "arguments": [123]
    }
  }
}
```

### Custom Context

Applications can attach arbitrary metadata:

```json
{
  "context": {
    "feature_flags": { "new_checkout": true },
    "deployment": "v2.3.1"
  }
}
```

## `server` Object

| Field | Type | Description |
|-------|------|-------------|
| `server.hostname` | string | Server hostname or instance ID |
| `server.pid` | integer | Process ID |
| `server.ruby_version` | string | Ruby version (e.g., `"4.0.2"`) |
| `server.rails_version` | string | Rails version (e.g., `"8.1.3"`) |

## Minimum Valid Payload

The smallest payload Oopsie accepts:

```json
{
  "error": {
    "class_name": "RuntimeError"
  }
}
```

Everything else is optional. Missing fields are stored as `null`.

## Forward Compatibility

The API tolerates unknown keys at any level of the payload. Future versions of ExceptionReporter may add fields — Oopsie will store them in the appropriate JSON column without breaking.

When updating the payload format:
- New optional fields can be added in any minor version
- Removing or renaming fields requires a major version bump
- The `version` field tracks which schema the payload conforms to

## How Oopsie Uses the Payload

| Payload Field | Oopsie Usage |
|---------------|-------------|
| `error.class_name` | ErrorGroup display name + fingerprint input |
| `error.first_line.file` + `error.first_line.method` | Primary fingerprint (SHA256 hash) |
| `error.message` | Fallback fingerprint (normalized) + display |
| `error.backtrace` | Displayed in error group detail view |
| `error.causes` | Stored for debugging context |
| `error.handled` | Stored on Occurrence (future: UI priority) |
| `app.environment` | Stored on Occurrence for filtering |
| `context` | Stored as JSON, displayed in detail view |
| `server` | Stored as JSON, displayed in detail view |
| `timestamp` | Occurrence `occurred_at` |
| `version` | Stored as `notifier_version` |

## Rate Limiting

The API enforces a rate limit of **100 requests per minute per project**. Exceeding this returns `429 Too Many Requests`. The limit resets each calendar minute.
