# Pass 2 - Data Model and Interaction Layer

## SQLite Decision

Use a **separate Middleman V2 SQLite database**.

- Do not write deterministic execution state into Spacebot's internal SQLite.
- Keep Spacebot and Middleman as separate bounded contexts.
- Allow Spacebot to query Middleman via API/events, not shared table writes.

Reason:
- Independent schema evolution.
- Lower blast radius.
- Stronger reliability and replay guarantees.
- Easier backup/recovery and forensic analysis.

## Storage Layout

- `~/.middleman-v2/state.db` (authoritative deterministic state)
- `~/.middleman-v2/events/*.jsonl` (append-only event stream snapshots)
- `~/.middleman-v2/config/*.yaml` (policy and routing config)

## Core Entities

## `projects`
- `project_id` (pk)
- `name`
- `root_path`
- `default_machine` (`mbp` | `studio`)
- `created_at`, `updated_at`

## `managers`
- `manager_id` (pk)
- `project_id` (fk)
- `status` (`active` | `paused` | `degraded`)
- `last_heartbeat_at`
- `created_at`, `updated_at`

## `open_efforts`
- `effort_id` (pk)
- `project_id` (fk)
- `source` (`local` | `github`)
- `repo`, `branch`, `worktree_path`, `session_id`
- `status` (`active` | `blocked` | `paused` | `completed` | `stale`)
- `activity_state` (`active_now` | `recently_active`)
- `last_activity_at`
- `summary`
- `owner`
- `links_json` (`pr`, `thread`, `commit`)

## `queues`
- `queue_id` (pk)
- `project_id` (fk)
- `queue_key` (unique) (`owner/repo#pr:head_branch`)
- `status` (`running` | `paused`)
- `active_item_id` (nullable)
- `last_polled_at`

## `queue_items`
- `queue_item_id` (pk)
- `queue_id` (fk)
- `github_comment_id`
- `fingerprint`
- `position_index`
- `state` (`pending` | `running` | `succeeded` | `failed` | `skipped` | `blocked`)
- `attempt_count`
- `enqueued_at`, `started_at`, `completed_at`

## `attempts`
- `attempt_id` (pk)
- `queue_item_id` (fk)
- `attempt_number`
- `session_id`
- `worker_id`
- `result` (`ok` | `failed`)
- `error_code`, `error_summary`
- `created_at`

## `worktrees`
- `worktree_id` (pk)
- `project_id` (fk)
- `path`
- `branch`
- `status` (`idle` | `in_use` | `recycling`)
- `last_activity_at`
- `ahead_of_origin` (bool)

## `idempotency_keys`
- `idempotency_key` (pk)
- `scope` (`poll` | `reply` | `transition` | `push`)
- `resource_id`
- `created_at`

## `events`
- `event_id` (pk)
- `project_id` (fk)
- `event_type`
- `entity_type`
- `entity_id`
- `payload_json`
- `created_at`

## Interaction Layer (Spacebot <-> Middleman)

Transport:
- Command API (HTTP)
- Event stream (WebSocket or SSE)
- Optional periodic pull endpoints for dashboards

## Commands (Spacebot -> Middleman)

- `queue.enqueue_comments`
- `queue.pause`
- `queue.resume`
- `queue.retry_item`
- `queue.skip_item`
- `queue.status`
- `worker.spawn`
- `worker.message`
- `effort.refresh`
- `effort.map`
- `worktree.allocate`
- `worktree.release`
- `session.attach_hint`

## Query Endpoints (Spacebot -> Middleman)

- `GET /projects/:id/open-efforts`
- `GET /projects/:id/queues`
- `GET /queues/:queueKey/status`
- `GET /queue-items/:id/attempts`
- `GET /events?since=<cursor>`

## Events (Middleman -> Spacebot)

- `queue.item_started`
- `queue.item_succeeded`
- `queue.item_failed`
- `queue.paused_exhausted`
- `worktree.recycled`
- `policy.violation_blocked`
- `rate_limit.degraded_mode`

## Consistency Rules

- Every queue transition writes one DB transaction and one event record.
- Event records are immutable.
- Crash recovery rebuilds in-flight states from `queue_items` + `attempts` + `events`.
- Idempotency checks are performed before external side effects.

Polling high-water marks:
- keep `updated_at` + `comment_id` markers per queue key.

Local effort inclusion thresholds:
- `active_now` if activity is within 30 minutes.
- `recently_active` if activity is within 14 days and not active_now.

## Security and Isolation Rules

- Separate auth/secret scope per project manager profile.
- No protected branch writes by automation.
- Commands requiring state mutation must include operator/session provenance.
- Spacebot is not allowed to bypass deterministic queue constraints.
