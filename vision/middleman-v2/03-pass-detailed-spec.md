# Pass 3 - Middleman V2 Detailed Spec

## Scope

Middleman V2 is the deterministic execution kernel under Spacebot.
It handles PR queues, retries, idempotency, worktree constraints, policy gates, and recoverable execution.

Spacebot remains the only user-facing orchestration surface.

## Functional Modules

## 1. Intake and Polling Engine

- Poll GitHub for review comments + PR-linked issue comments.
- Maintain high-water marks per queue key.
- Deduplicate by `comment_id` + fingerprint.
- Adaptive poll interval with jitter and rate-limit awareness.
- Support event intake for `pull_request_review_comment` and PR-linked `issue_comment`.
- Use conditional requests (`ETag`, `If-None-Match`) and `Retry-After` handling.

## 2. Queue Engine

- Queue key: `owner/repo#pr_number:head_branch`.
- Strict FIFO ordering per key.
- Exactly one active item per queue key.
- Support pause/resume/skip/retry commands.
- Backlog continues accumulating while queue key is paused.

## 3. Attempt Engine

- Max 3 attempts per queue item.
- Retry must stay on same session lineage.
- On exhaustion: leave unresolved, post blocker, pause queue key, emit escalation event.

## 4. Worktree Manager

- Hard cap: 30 active worktrees per project.
- Reuse eligible branch worktree when possible.
- Recycle oldest eligible only when policy allows.
- 14-day recency confirmation gate for potentially active worktrees.
- Reuse reset procedure: fetch origin -> detect default branch -> hard reset to `origin/<default_branch>` -> clean untracked files -> bind to task.

## 5. Policy Guard Kernel

- Block protected branch pushes (`main`, `master`, `staging`).
- Restrict pushes to allowed PR head branches only.
- Enforce merge strategy contract (fetch/pull/merge no rebase).
- Block execution on policy mismatch and emit violation event.

## 6. Side-Effect Executor

- Execute deterministic action plans for:
  - branch sync
  - tests/typecheck
  - commit/push
  - PR reply and optional resolve
- Record precondition checks before each irreversible step.

## 7. State and Recovery Engine

- Write all transitions transactionally.
- Persist immutable event log.
- On restart, reconstruct in-flight work and continue without duplicate processing.

## 8. Notification Bridge

- Emit structured events for Spacebot to summarize to user.
- Success payload includes:
  - commit link
  - original comment
  - concise change summary
  - `session_id`
  - `worktree_path`
- Include direct attach command in notifications: `opencode -s <session_id>`

## 9. Baseline Knowledge Index

- Source baseline context from all `AGENTS.md` files in each project.
- Refresh baseline index on every push.
- Keep baseline lightweight; deep dives are on-demand.

## 10. Operator Command Surface (Spacebot-facing)

- `retry <queue_item_id>`
- `resume <queue_key>`
- `skip <queue_item_id>`
- `status <queue_key>`
- `map <project>`
- `attach <session_id>`

## Required Contracts

## Queue Transition Contract

For each queue item transition:
1. Validate current state and lock queue key.
2. Apply transition.
3. Persist transition + idempotency marker.
4. Emit event.
5. Release lock.

If step 3 or 4 fails, rollback transition.

## Retry Prompt Contract (from Spacebot)

Spacebot must provide for each retry:
- original reviewer comment
- diagnostics from previous attempt
- what changed since previous attempt
- explicit done criteria

Middleman validates fields exist before spawning retry.

## Completion Gate Contract

Item can only complete when all are true:
- tests pass
- typecheck passes
- commit exists
- push succeeds
- PR reply posted

If any fail, item remains incomplete.

## Non-Functional Requirements

- Determinism over creativity for state transitions.
- End-to-end observability with event correlation IDs.
- Replay safety after crashes/restarts.
- Low operational ambiguity for on-call debugging.

## API Surface (Minimum)

## Commands

- `POST /commands/enqueue-comments`
- `POST /commands/pause-queue`
- `POST /commands/resume-queue`
- `POST /commands/retry-item`
- `POST /commands/skip-item`
- `POST /commands/reconcile-open-efforts`

## Queries

- `GET /status/projects/:projectId`
- `GET /status/queues/:queueKey`
- `GET /status/items/:queueItemId`
- `GET /status/worktrees/:projectId`
- `GET /status/events?cursor=<cursor>`

## Event Taxonomy

- Queue: `enqueued`, `started`, `succeeded`, `failed`, `paused`, `resumed`
- Attempt: `attempt_started`, `attempt_failed`, `attempt_exhausted`
- Worktree: `allocated`, `reused`, `recycled`, `recycle_blocked`
- Policy: `violation`, `push_blocked`, `branch_guard_triggered`
- System: `recovery_started`, `recovery_completed`, `degraded_mode`

## Build Phases

## Phase A - Deterministic Core

- Implement state schema, queue engine, idempotency keys, event log.
- Add restart/recovery path and replay tests.

## Phase B - Execution Integration

- Integrate worker/session dispatch and completion gates.
- Add branch policy and push guard enforcement.

## Phase C - Spacebot Integration

- Wire command/query/event bridge to Spacebot Hands.
- Add operator commands and user notification templates.

## Phase D - Hardening

- Load tests on active PR queues.
- Chaos tests for crash/restart mid-attempt.
- Rate-limit degraded mode validation.

## Acceptance Criteria

1. FIFO order is preserved under concurrent polling updates.
2. No queue item is processed twice under replay conditions.
3. Retry loop halts at attempt 3 and pauses queue key.
4. Worktree cap (30/project) is never exceeded.
5. Protected branch pushes are always blocked.
6. Crash recovery resumes safely without duplicate side effects.
7. Spacebot receives complete event payload for every state transition.
8. MBP is default routing target unless Studio override is explicitly requested.
9. Success notifications include commit link, original comment, summary, session_id, worktree_path, and attach hint.

## Out of Scope (V2)

- Autonomous merge to protected branches.
- Cross-machine automatic session migration.
- Full semantic knowledge graph.
